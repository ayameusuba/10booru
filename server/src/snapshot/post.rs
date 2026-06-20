use crate::api::error::{ApiError, ApiResult};
use crate::auth::Client;
use crate::model::enums::{PostFlag, PostFlags, PostSafety, ResourceOperation, ResourceType};
use crate::model::post::{Post, PostNote};
use crate::model::post_revision::NewPostRevision;
use crate::model::snapshot::NewSnapshot;
use crate::model::tag::TagName;
use crate::resource::post::Note;
use crate::schema::{
    post, post_feature, post_note, post_relation, post_revision, post_tag, tag_name,
};
use crate::snapshot;
use crate::string::{LargeString, SmallString};
use diesel::{
    ExpressionMethods, JoinOnDsl, OptionalExtension, PgConnection, QueryDsl, QueryResult,
    RunQueryDsl, SelectableHelper,
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::collections::HashSet;

#[derive(Clone, Serialize)]
pub struct SnapshotData {
    pub safety: PostSafety,
    pub checksum: String,
    pub flags: PostFlags,
    pub source: LargeString,
    pub description: LargeString,
    pub tags: Vec<SmallString>,
    pub relations: Vec<i64>,
    pub notes: Vec<Note>,
    pub featured: bool,
}

impl SnapshotData {
    pub fn retrieve(conn: &mut PgConnection, post: Post) -> QueryResult<Self> {
        let tags = tag_name::table
            .inner_join(post_tag::table.on(tag_name::tag_id.eq(post_tag::tag_id)))
            .select(tag_name::name)
            .filter(post_tag::post_id.eq(post.id))
            .filter(TagName::primary())
            .load(conn)?;
        let relations = post_relation::table
            .select(post_relation::child_id)
            .filter(post_relation::parent_id.eq(post.id))
            .load(conn)?;
        let notes = post_note::table
            .select(PostNote::as_select())
            .filter(post_note::post_id.eq(post.id))
            .load(conn)?;
        let latest_feature = post_feature::table
            .select(post_feature::post_id)
            .order(post_feature::time.desc())
            .first(conn)
            .optional()?;
        Ok(Self {
            safety: post.safety,
            checksum: hex::encode(&post.checksum),
            flags: post.flags,
            source: post.source,
            description: post.description,
            tags,
            relations,
            notes: notes.into_iter().map(Note::new).collect(),
            featured: latest_feature == Some(post.id),
        })
    }

    fn sort_fields(&mut self) {
        self.tags.sort_unstable();
        self.relations.sort_unstable();
        self.notes.sort_unstable_by_key(Note::id);
    }
}

#[derive(Clone, Deserialize)]
pub struct RevisionData {
    pub safety: PostSafety,
    pub flags: Vec<PostFlag>,
    pub source: LargeString,
    pub description: LargeString,
    pub tags: Vec<SmallString>,
    pub relations: Vec<i64>,
    pub notes: Vec<Note>,
}

impl RevisionData {
    pub fn from_value(value: Value) -> ApiResult<Self> {
        serde_json::from_value(value).map_err(ApiError::from)
    }

    pub fn flags(&self) -> PostFlags {
        PostFlags::from_slice(&self.flags)
    }
}

pub fn revision_data_from_snapshot(mut post_data: SnapshotData) -> ApiResult<Value> {
    post_data.sort_fields();
    let mut data = serde_json::to_value(post_data)?;
    let object = data
        .as_object_mut()
        .expect("Post snapshot data must serialize to an object");

    object.remove("checksum");
    object.remove("featured");
    Ok(data)
}

pub fn revision_data(conn: &mut PgConnection, post: Post) -> ApiResult<Value> {
    revision_data_from_snapshot(SnapshotData::retrieve(conn, post)?)
}

pub fn save_revision(
    conn: &mut PgConnection,
    client: Client,
    post: Post,
    restored_from_revision_id: Option<i64>,
) -> ApiResult<i64> {
    let post_id = post.id;
    NewPostRevision {
        post_id,
        user_id: client.id,
        restored_from_revision_id,
        data: revision_data(conn, post)?,
    }
    .insert(conn)
    .map_err(ApiError::from)
}

pub fn save_revisions(
    conn: &mut PgConnection,
    client: Client,
    mut post_ids: Vec<i64>,
) -> ApiResult<()> {
    post_ids.sort_unstable();
    post_ids.dedup();
    if post_ids.is_empty() {
        return Ok(());
    }

    let posts: Vec<Post> = post::table
        .filter(post::id.eq_any(&post_ids))
        .select(Post::as_select())
        .load(conn)?;

    if posts.len() != post_ids.len() {
        return Err(ApiError::NotFound(ResourceType::Post));
    }

    for post in posts {
        save_revision(conn, client, post, None)?;
    }
    Ok(())
}

pub fn save_initial_revisions(
    conn: &mut PgConnection,
    client: Client,
    mut post_ids: Vec<i64>,
) -> ApiResult<()> {
    post_ids.sort_unstable();
    post_ids.dedup();
    if post_ids.is_empty() {
        return Ok(());
    }

    let revised_post_ids: HashSet<i64> = post_revision::table
        .select(post_revision::post_id)
        .filter(post_revision::post_id.eq_any(&post_ids))
        .distinct()
        .load::<i64>(conn)?
        .into_iter()
        .collect();

    let initial_post_ids: Vec<i64> = post_ids
        .into_iter()
        .filter(|post_id| !revised_post_ids.contains(post_id))
        .collect();
    if initial_post_ids.is_empty() {
        return Ok(());
    }

    let posts: Vec<Post> = post::table
        .filter(post::id.eq_any(initial_post_ids))
        .select(Post::as_select())
        .load(conn)?;

    for post in posts {
        save_revision(conn, client, post, None)?;
    }
    Ok(())
}

pub fn creation_snapshot(
    conn: &mut PgConnection,
    client: Client,
    post_id: i64,
    post_data: SnapshotData,
) -> ApiResult<()> {
    unary_snapshot(conn, client, post_id, post_data, ResourceOperation::Created)
}

pub fn feature_snapshot(
    conn: &mut PgConnection,
    client: Client,
    old_featured_post_id: Option<i64>,
    new_featured_post_id: i64,
) -> QueryResult<()> {
    const PANIC_MESSAGE: &str = "There must be a diff";
    if old_featured_post_id == Some(new_featured_post_id) {
        return Ok(());
    }

    let featured_data = json!({"featured": true});
    let not_featured_data = json!({"featured": false});

    if let Some(old_featured_post_id) = old_featured_post_id {
        let old_feature_diff =
            snapshot::value_diff(featured_data.clone(), not_featured_data.clone())
                .expect(PANIC_MESSAGE);
        NewSnapshot {
            user_id: client.id,
            operation: ResourceOperation::Modified,
            resource_type: ResourceType::Post,
            resource_id: old_featured_post_id.into(),
            data: old_feature_diff,
        }
        .insert(conn)?;
    }

    let new_feature_diff =
        snapshot::value_diff(not_featured_data, featured_data).expect(PANIC_MESSAGE);
    NewSnapshot {
        user_id: client.id,
        operation: ResourceOperation::Modified,
        resource_type: ResourceType::Post,
        resource_id: new_featured_post_id.into(),
        data: new_feature_diff,
    }
    .insert(conn)?;
    Ok(())
}

pub fn merge_snapshot(
    conn: &mut PgConnection,
    client: Client,
    absorbed_post_id: i64,
    merge_to_post_id: i64,
) -> QueryResult<()> {
    let data = json!([ResourceType::Post, merge_to_post_id]);
    NewSnapshot {
        user_id: client.id,
        operation: ResourceOperation::Merged,
        resource_type: ResourceType::Post,
        resource_id: absorbed_post_id.into(),
        data,
    }
    .insert(conn)
}

pub fn modification_snapshot(
    conn: &mut PgConnection,
    client: Client,
    post_id: i64,
    mut old: SnapshotData,
    mut new: SnapshotData,
) -> ApiResult<()> {
    old.sort_fields();
    new.sort_fields();
    let old_data = serde_json::to_value(old)?;
    let new_data = serde_json::to_value(new)?;
    if let Some(data) = snapshot::value_diff(old_data, new_data) {
        NewSnapshot {
            user_id: client.id,
            operation: ResourceOperation::Modified,
            resource_type: ResourceType::Post,
            resource_id: post_id.into(),
            data,
        }
        .insert(conn)?;
    }
    Ok(())
}

pub fn deletion_snapshot(
    conn: &mut PgConnection,
    client: Client,
    post_id: i64,
    post_data: SnapshotData,
) -> ApiResult<()> {
    unary_snapshot(conn, client, post_id, post_data, ResourceOperation::Deleted)
}

pub fn unary_snapshot(
    conn: &mut PgConnection,
    client: Client,
    post_id: i64,
    mut post_data: SnapshotData,
    operation: ResourceOperation,
) -> ApiResult<()> {
    post_data.sort_fields();
    serde_json::to_value(post_data)
        .map_err(ApiError::from)
        .and_then(|data| {
            NewSnapshot {
                user_id: client.id,
                operation,
                resource_type: ResourceType::Post,
                resource_id: post_id.into(),
                data,
            }
            .insert(conn)
            .map_err(ApiError::from)
        })
}
