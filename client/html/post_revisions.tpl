<div class='post-revisions'>
    <% if (ctx.error) { %>
        <p class='revision-error'><%- ctx.error %></p>
    <% } %>

    <% if (ctx.loading && !ctx.revisions.length) { %>
        <p>Loading history…</p>
    <% } else if (!ctx.revisions.length) { %>
        <p>No saved metadata revisions.</p>
    <% } else { %>
        <ol class='revision-list'>
            <% for (let index = 0; index < ctx.revisions.length; index++) { %>
                <% const revision = ctx.revisions[index]; %>
                <% const olderRevision = ctx.revisions[index + 1] || null; %>
                <% const data = revision.data || {}; %>
                <li class='revision'>
                    <div class='revision-header'>
                        <strong>Revision #<%- revision.id %></strong>
                        <span class='revision-time'>
                            <%= ctx.makeExactTime(revision.creationTime) %>
                        </span>
                    </div>

                    <div class='revision-meta revision-editor'>
                        Saved by <%= ctx.makeUserLink(revision.user) %>
                    </div>

                    <p class='revision-summary'>
                        <%= ctx.formatSummary(revision, olderRevision) %>
                    </p>

                    <button
                        type='button'
                        class='restore-revision'
                        data-revision-id='<%- revision.id %>'
                        <% if (ctx.restoringRevisionId === revision.id) { %>disabled<% } %>>
                        <% if (ctx.restoringRevisionId === revision.id) { %>
                            Restoring…
                        <% } else { %>
                            Restore metadata
                        <% } %>
                    </button>

                    <details class='revision-details'>
                        <summary>Show saved metadata</summary>
                        <dl>
                            <div>
                                <dt>Safety</dt>
                                <dd><%- ctx.asText(data.safety) %></dd>
                            </div>
                            <div>
                                <dt>Flags</dt>
                                <dd><%- ctx.formatList(data.flags) %></dd>
                            </div>
                            <div>
                                <dt>Tags</dt>
                                <dd><%= ctx.formatTags(data.tags) %></dd>
                            </div>
                            <div>
                                <dt>Relations</dt>
                                <dd><%- ctx.formatRelations(data.relations) %></dd>
                            </div>
                            <div>
                                <dt>Source</dt>
                                <dd><pre><%- ctx.asText(data.source) %></pre></dd>
                            </div>
                            <div>
                                <dt>Description</dt>
                                <dd><pre><%- ctx.asText(data.description) %></pre></dd>
                            </div>
                            <div>
                                <dt>Notes</dt>
                                <dd><pre><%- ctx.formatNotes(data.notes) %></pre></dd>
                            </div>
                        </dl>
                    </details>
                </li>
            <% } %>
        </ol>
    <% } %>

    <% if (ctx.hasMore) { %>
        <button type='button' class='load-more-revisions' <% if (ctx.loading) { %>disabled<% } %>>
            <% if (ctx.loading) { %>Loading…<% } else { %>Load older revisions<% } %>
        </button>
    <% } %>
</div>
