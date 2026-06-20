use crate::model::post::Post;
use crate::model::user::User;
use crate::schema::post_revision;
use crate::time::DateTime;
use diesel::pg::Pg;
use diesel::{
    Associations, Identifiable, Insertable, PgConnection, QueryResult, Queryable, RunQueryDsl,
    Selectable,
};
use serde_json::Value;

#[derive(Insertable)]
#[diesel(table_name = post_revision)]
#[diesel(check_for_backend(Pg))]
pub struct NewPostRevision {
    pub post_id: i64,
    pub user_id: Option<i64>,
    pub restored_from_revision_id: Option<i64>,
    pub data: Value,
}

impl NewPostRevision {
    pub fn insert(self, conn: &mut PgConnection) -> QueryResult<i64> {
        let revision: PostRevision = self.insert_into(post_revision::table).get_result(conn)?;
        Ok(revision.id)
    }
}

#[derive(Associations, Identifiable, Queryable, Selectable)]
#[diesel(belongs_to(Post))]
#[diesel(belongs_to(User))]
#[diesel(table_name = post_revision)]
#[diesel(check_for_backend(Pg))]
pub struct PostRevision {
    pub id: i64,
    pub post_id: i64,
    pub user_id: Option<i64>,
    pub restored_from_revision_id: Option<i64>,
    pub data: Value,
    pub creation_time: DateTime,
}
