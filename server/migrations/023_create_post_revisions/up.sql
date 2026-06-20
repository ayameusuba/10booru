CREATE TABLE "post_revision" (
    "id" BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "post_id" BIGINT NOT NULL,
    "user_id" BIGINT REFERENCES "user" ON DELETE SET NULL,
    "restored_from_revision_id" BIGINT REFERENCES "post_revision" ON DELETE SET NULL,
    "data" JSONB NOT NULL,
    "creation_time" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "post_revision_post_id_id_index"
ON "post_revision" ("post_id", "id" DESC);
