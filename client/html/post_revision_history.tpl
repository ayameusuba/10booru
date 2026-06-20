<div class='post-history-page'>
    <h1>History</h1>

    <% if (ctx.loading) { %>
        <p>Loading history…</p>
    <% } else if (ctx.error) { %>
        <p class='post-history-error'><%- ctx.error %></p>
    <% } else { %>
        <p class='post-history-post'>
            <a href='<%= ctx.postUrl %>'>Post @<%- ctx.post.id %></a>
        </p>
        <div class='post-revisions-container'></div>
    <% } %>
</div>
