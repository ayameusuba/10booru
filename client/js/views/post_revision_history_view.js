"use strict";

const Post = require("../models/post.js");
const topNavigation = require("../models/top_navigation.js");
const views = require("../util/views.js");
const uri = require("../util/uri.js");
const PostRevisionListControl = require("../controls/post_revision_list_control.js");

const template = views.getTemplate("post-revision-history");

class PostRevisionHistoryView {
    constructor(postId) {
        this._hostNode = document.getElementById("content-holder");

        topNavigation.activate("");
        topNavigation.setTitle("History");

        this._render({ loading: true, error: "", post: null });
        Post.get(postId).then(
            (post) => {
                this._render({ loading: false, error: "", post: post });
                this._revisionListControl = new PostRevisionListControl(
                    this._hostNode.querySelector(".post-revisions-container"),
                    post
                );
            },
            (error) => {
                this._render({
                    loading: false,
                    error: error.message || "Failed to load this post.",
                    post: null,
                });
            }
        );
    }

    _render(ctx) {
        if (ctx.post) {
            ctx.postUrl = uri.formatClientLink("post", ctx.post.id);
        }
        views.replaceContent(this._hostNode, template(ctx));
    }
}

module.exports = PostRevisionHistoryView;
