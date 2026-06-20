<div class='readonly-sidebar'>
    <article class='details'>

        <section class='social'>
            <div class='score-container'></div>

            <div class='fav-container'></div>
        </section>

        <h1 class='statistics-header'>Statistics</h1>
        <div class='statistics-body'>
        <section class='download'>
            <a target='_blank' rel='external noopener noreferrer' href='<%- ctx.post.contentUrl %>'>
                <i class='fa fa-download'></i><!--
            --><%= ctx.makeFileSize(ctx.post.fileSize) %> <!--
                --><%- {
                    'image/gif': 'GIF',
                    'image/jpeg': 'JPEG',
                    'image/png': 'PNG',
                    'image/webp': 'WEBP',
                    'image/bmp': 'BMP',
                    'image/avif': 'AVIF',
                    'image/heif': 'HEIF',
                    'image/heic': 'HEIC',
                    'video/webm': 'WEBM',
                    'video/mp4': 'MPEG-4',
                    'video/quicktime': 'MOV',
                    'application/x-shockwave-flash': 'SWF',
                }[ctx.post.mimeType] %><!--
            --></a>
            (<%- ctx.post.canvasWidth %>x<%- ctx.post.canvasHeight %>)
            <% if (ctx.post.flags.length) { %><!--
                --><% if (ctx.post.flags.includes('loop')) { %><i class='fa fa-repeat'></i><% } %><!--
                --><% if (ctx.post.flags.includes('sound')) { %><i class='fa fa-volume-up'></i><% } %>
            <% } %>
        </section>

        <section class='upload-info'>
            <%= ctx.makeUserLink(ctx.post.user) %>,
            <%= ctx.makeExactTime(ctx.post.creationTime) %>
        </section>

        <% if (ctx.enableSafety) { %>
            <section class='safety'>
                <i class='fa fa-circle safety-<%- ctx.post.safety %>'></i><!--
                --><%- ctx.post.safety[0].toUpperCase() + ctx.post.safety.slice(1) %>
            </section>
        <% } %>

            <section class='post-id'><a href='<%= ctx.getPostUrl(ctx.post.id, ctx.parameters) %>'>@<%- ctx.post.id %></a></section>

        <section class='zoom'>
            <a href class='fit-original'>Original zoom</a> &middot;
            <a href class='fit-width'>fit width</a> &middot;
            <a href class='fit-height'>height</a> &middot;
            <a href class='fit-both'>both</a>
        </section>

        <% if (ctx.post.source) { %>
            <section class='source'>Source: <% for (let i = 0; i < ctx.post.sourceSplit.length; i++) { %><% if (i != 0) { %>&middot; <% } %><a href='<%- ctx.post.sourceSplit[i] %>' title='<%- ctx.post.sourceSplit[i] %>'><%- ctx.post.sourceSplit[i] %></a><% } %></section>
        <% } %>

        <section class='search'>
            Search on
            <a target='_blank' rel='external noopener' href='https://lens.google.com/uploadbyurl?url=<%- encodeURIComponent(ctx.post.fullContentUrl) %>'>G</a> &middot;
            <a target='_blank' rel='external noopener' href='https://saucenao.com/search.php?db=999&hide=0&url=<%- encodeURIComponent(ctx.post.fullContentUrl) %>'>Sn</a> &middot;
            <a target='_blank' rel='external noopener' href='https://ascii2d.net/search/url/<%- encodeURIComponent(ctx.post.fullContentUrl) %>'>As</a> &middot;
            <a target='_blank' rel='external noopener' href='https://iqdb.org/?url=<%- encodeURIComponent(ctx.post.fullContentUrl) %>'>Iq</a> &middot;
            <a target='_blank' rel='external noopener' href='https://danbooru.donmai.us/posts?tags=md5:<%- ctx.post.checksumMD5 %>'>Db</a> &middot;
            <a target='_blank' rel='external noopener' href='https://gelbooru.com/index.php?page=post&s=list&tags=md5:<%- ctx.post.checksumMD5 %>'>Gb</a> &middot;
            <% if (ctx.post.checksumSHA1) { %><a target='_blank' rel='external noopener' href='https://exhentai.org/?fs_similar=1&fs_exp=1&f_shash=<%- ctx.post.checksumSHA1 %>'>Ex</a> &middot;<% } %>
            <a target='_blank' rel='external noopener' href='https://trace.moe/?url=<%- encodeURIComponent(ctx.post.fullContentUrl) %>'>Tm</a>
        </section>
        </div>
    </article>

    <% if (ctx.post.relations.length) { %>
        <nav class='relations'>
            <h1>Relations (<%- ctx.post.relations.length %>)</h1>
            <ul><!--
                --><% for (let post of ctx.post.relations) { %><!--
                    --><li><!--
                        --><a href='<%= ctx.getPostUrl(post.id, ctx.parameters) %>'><!--
                            --><%= ctx.makeThumbnail(post.thumbnailUrl) %><!--
                        --></a><!--
                    --></li><!--
                --><% } %><!--
            --></ul>
        </nav>
    <% } %>

    <nav class='tags'>
        <% if (ctx.post.tags.length) { %>
            <% const tagCategoryLabels = {
                default: "Uncategorized:",
                artist: "Artist:",
                character: "Character:",
                copyright: "Copyright:",
                general: "General:",
                meta: "Meta:",
            }; %>
            <% const tagCategoryOrder = ["default", "artist", "character", "copyright", "general", "meta"]; %>
            <% const tagsByCategory = {}; %>

            <% for (let tag of ctx.post.tags) { %>
                <% const rawCategory = tag.category || "default"; %>
                <% const displayCategory = tagCategoryLabels[rawCategory] ? rawCategory : "general"; %>
                <% if (!tagsByCategory[displayCategory]) { tagsByCategory[displayCategory] = []; } %>
                <% tagsByCategory[displayCategory].push(tag); %>
            <% } %>

            <% for (let category of tagCategoryOrder) { %>
                <% const tags = tagsByCategory[category] || []; %>
                <% if (tags.length) { %>
                    <h2 class='tag-category-header'><%- tagCategoryLabels[category] %></h2>
                    <ul class='compact-tags'><!--
                        --><% for (let tag of tags) { %><!--
                            --><li><!--
                                --><% if (ctx.canViewTags) { %><!--
                                --><a href='<%- ctx.formatClientLink('tag', tag.names[0]) %>' class='<%= ctx.makeCssName(tag.category || "default", 'tag') %>'><!--
                                    --><i class='fa fa-tag'></i><!--
                                --><% } %><!--
                                --><% if (ctx.canViewTags) { %><!--
                                    --></a><!--
                                --><% } %><!--
                                --><% if (ctx.canListPosts) { %><!--
                                    --><a href='<%- ctx.formatClientLink('posts', {query: ctx.escapeTagName(tag.names[0])}) %>' class='<%= ctx.makeCssName(tag.category || "default", 'tag') %>'><!--
                                --><% } %><!--
                                    --><%- ctx.getPrettyName(tag.names[0]) %><!--
                                --><% if (ctx.canListPosts) { %><!--
                                    --></a><!--
                                --><% } %>&#32;<!--
                                --><span class='tag-usages' data-pseudo-content='<%- tag.postCount %>'></span><!--
                            --></li><!--
                        --><% } %><!--
                    --></ul>
                <% } %>
            <% } %>
        <% } else { %>
            <p>
                No tags yet!
                <% if (ctx.canEditPosts) { %>
                    <a href='<%= ctx.getPostEditUrl(ctx.post.id, ctx.parameters) %>'>Add some.</a>
                <% } %>
            </p>
        <% } %>
    </nav>

    <% if (ctx.canRestorePosts) { %>
        <section class='post-history-link'>
            <a href='<%= ctx.postHistoryUrl %>'>
                <i class='fa fa-history'></i>
                History
            </a>
        </section>
    <% } %>
</div>
