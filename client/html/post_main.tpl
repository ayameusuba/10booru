<div class='content-wrapper transparent-container post-view'>
    <aside class='sidebar'>
        <nav class='buttons'>
            <article class='previous-post'>
                <% if (ctx.prevPostId) { %>
                    <% if (ctx.editMode) { %>
                        <a rel='prev' href='<%= ctx.getPostEditUrl(ctx.prevPostId, ctx.parameters) %>'>
                    <% } else { %>
                        <a rel='prev' href='<%= ctx.getPostUrl(ctx.prevPostId, ctx.parameters) %>'>
                    <% } %>
                <% } else { %>
                    <a rel='prev' class='inactive'>
                <% } %>
                    <i class='fa fa-chevron-left'></i>
                    <span class='vim-nav-hint'>&lt; Previous post</span>
                </a>
            </article>
            <article class='next-post'>
                <% if (ctx.nextPostId) { %>
                    <% if (ctx.editMode) { %>
                        <a rel='next' href='<%= ctx.getPostEditUrl(ctx.nextPostId, ctx.parameters) %>'>
                    <% } else { %>
                        <a rel='next' href='<%= ctx.getPostUrl(ctx.nextPostId, ctx.parameters) %>'>
                    <% } %>
                <% } else { %>
                    <a rel='next' class='inactive'>
                <% } %>
                    <i class='fa fa-chevron-right'></i>
                    <span class='vim-nav-hint'>Next post &gt;</span>
                </a>
            </article>
            <% if (ctx.canEditPosts || ctx.canDeletePosts || ctx.canFeaturePosts) { %>
            <article class='edit-post'>
                <% if (ctx.editMode) { %>
                    <a href='<%= ctx.getPostUrl(ctx.post.id, ctx.parameters) %>'>
                        <i class='fa fa-reply'></i>
                        <span class='vim-nav-hint'>Back to view mode</span>
                    </a>
                <% } else { %>
                    <a href='<%= ctx.getPostEditUrl(ctx.post.id, ctx.parameters) %>'>
                    <i class='fa fa-pencil'></i>
                    <span class='vim-nav-hint'>Edit post</span>
                    </a>
                <% } %>
            </article>
            <% } %>
        </nav>

        <div class='sidebar-container'></div>
    </aside>

    <div class='content'>
<% if (!ctx.editMode && ctx.post.relations && ctx.post.relations.length) { %>
    <section class='post-relation-strip'>
        <div class='post-relation-strip-header'>
            This post has
            <%- ctx.post.relations.length %>
            related <%- ctx.post.relations.length === 1 ? 'post' : 'posts' %>
            <a href='#' class='post-relation-strip-toggle'>hide «</a>
        </div>

        <div class='post-relation-strip-posts'>
            <a class='post-relation-strip-thumbnail current'
                href='<%- ctx.formatClientLink("post", ctx.post.id) %>'
                title='Current post @<%- ctx.post.id %>'>
                <%= ctx.makeThumbnail(ctx.post.thumbnailUrl) %>
            </a>

            <% for (let post of ctx.post.relations) { %>
            <a class='post-relation-strip-thumbnail'
                href='<%- ctx.formatClientLink("post", post.id) %>'
                title='Related post @<%- post.id %>'>
                <%= ctx.makeThumbnail(post.thumbnailUrl) %>
            </a>
            <% } %>
        </div>
    </section>
<% } %>

        <div class='post-container'></div>

        <% if (ctx.editMode && ctx.canEditPostDescription) { %>
            <h2>Description</h2>
            <%= ctx.makeTextarea({
                id: 'post-description',
                value: ctx.post.description,
            }) %>
        <% } else if (ctx.post.description != undefined && ctx.post.description != '') { %>
            <div class='description-container'>
                <details open>
                    <summary>Description</summary>
                    <%= ctx.makeMarkdown(ctx.post.description) %>
                </details>
            </div>
        <% } %>

        <div class='after-mobile-controls'>
            <% if (ctx.canCreateComments) { %>
                <h2>Add comment</h2>
                <div class='comment-form-container'></div>
            <% } %>

            <% if (ctx.canListComments) { %>
                <div class='comments-container'></div>
            <% } %>
        </div>
    </div>
</div>
