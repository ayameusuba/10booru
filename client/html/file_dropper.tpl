<div class='file-dropper-holder'>
    <input type='file' id='<%- ctx.id %>'/>

    <label class='file-dropper' for='<%- ctx.id %>' role='button'>
        <% if (ctx.selectDropText) { %>
        <%- ctx.selectDropText %>
        <% } else if (ctx.allowMultiple) { %>
        Drop files here!
        <br/>
        Or just click on this box.
        <% } else { %>
        Drop file here!
        <br/>
        Or just click on this box.
        <% } %>

        <% if (ctx.extraText) { %>
        <br/>
        <small><%= ctx.extraText %></small>
        <% } %>
    </label>

    <% if (ctx.allowUrls) { %>
    <% if (ctx.foldUrls) { %>
    <button type='button' class='url-toggle' aria-expanded='false'>Upload via URL</button>
    <% } %>

    <div class='url-holder'<% if (ctx.foldUrls) { %> hidden<% } %>>
        <input type='text' name='url' placeholder='<%- ctx.urlPlaceholder %>'/>
        <button type='button'><%- ctx.urlButtonText %></button>
    </div>
    <% } %>
</div>
