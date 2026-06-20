use crate::config::Config;
use crate::model::enums::AvatarStyle;
use crate::model::post_revision::PostRevision;
use crate::resource;
use crate::resource::field::Mask;
use crate::resource::user::MicroUser;
use crate::schema::{post_revision, user};
use crate::string::SmallString;
use crate::time::DateTime;
use diesel::{ExpressionMethods, PgConnection, QueryDsl, QueryResult, RunQueryDsl};
use serde::Serialize;
use serde_json::Value;
use serde_with::skip_serializing_none;
use server_macros::non_nullable_options;
use strum::EnumString;
use utoipa::ToSchema;

#[derive(Clone, Copy, EnumString)]
#[strum(serialize_all = "camelCase")]
pub enum Field {
    Id,
    User,
    RestoredFromRevisionId,
    Data,
    CreationTime,
}

impl From<Field> for u64 {
    fn from(value: Field) -> Self {
        value as u64
    }
}

/// A saved full metadata revision of a post.
#[non_nullable_options]
#[skip_serializing_none]
#[derive(Serialize, ToSchema)]
#[serde(rename_all = "camelCase")]
pub struct PostRevisionInfo {
    id: Option<i64>,
    user: Option<Option<MicroUser>>,
    restored_from_revision_id: Option<Option<i64>>,
    data: Option<Value>,
    creation_time: Option<DateTime>,
}

impl PostRevisionInfo {
    pub fn new_batch(
        conn: &mut PgConnection,
        config: &Config,
        revisions: Vec<PostRevision>,
        fields: Mask<Field>,
    ) -> QueryResult<Vec<Self>> {
        let batch_size = revisions.len();
        let mut users =
            resource::retrieve(fields[Field::User], || get_users(conn, config, &revisions))?;
        resource::check_batch_results(batch_size, users.len());

        let mut results = revisions
            .into_iter()
            .rev()
            .map(|revision| Self {
                id: fields[Field::Id].then_some(revision.id),
                user: users.pop(),
                restored_from_revision_id: fields[Field::RestoredFromRevisionId]
                    .then_some(revision.restored_from_revision_id),
                data: fields[Field::Data].then_some(revision.data),
                creation_time: fields[Field::CreationTime].then_some(revision.creation_time),
            })
            .collect::<Vec<_>>();
        results.reverse();
        Ok(results)
    }
}

fn get_users(
    conn: &mut PgConnection,
    config: &Config,
    revisions: &[PostRevision],
) -> QueryResult<Vec<Option<MicroUser>>> {
    let revision_ids: Vec<_> = revisions.iter().map(|revision| revision.id).collect();
    post_revision::table
        .inner_join(user::table)
        .select((post_revision::id, user::name, user::avatar_style))
        .filter(post_revision::id.eq_any(revision_ids))
        .load::<(i64, SmallString, AvatarStyle)>(conn)
        .map(|user_info| {
            resource::order_like(user_info, revisions, |&(id, ..)| id)
                .into_iter()
                .map(|user_info| {
                    user_info
                        .map(|(_, name, avatar_style)| MicroUser::new(config, name, avatar_style))
                })
                .collect()
        })
}
