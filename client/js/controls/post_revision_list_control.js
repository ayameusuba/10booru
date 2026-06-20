"use strict";

const api = require("../api.js");
const events = require("../events.js");
const misc = require("../util/misc.js");
const uri = require("../util/uri.js");
const views = require("../util/views.js");
const Tag = require("../models/tag.js");

const template = views.getTemplate("post-revisions");
const FIELDS = "id,user,restoredFromRevisionId,data,creationTime";
const PAGE_SIZE = 25;

function asArray(value) {
    return Array.isArray(value) ? value : [];
}

function asText(value) {
    return value === undefined || value === null || value === ""
        ? "(empty)"
        : String(value);
}

function escape(value) {
    return misc.escapeHtml(String(value));
}

function formatList(value) {
    const values = asArray(value).map(String);
    return values.length ? values.join(", ") : "None";
}

function formatRelations(value) {
    const values = asArray(value);
    return values.length ? values.map((id) => `@${id}`).join(", ") : "None";
}

function formatNotes(value) {
    const notes = asArray(value);
    if (!notes.length) {
        return "None";
    }

    return notes
        .map((note, index) => {
            const points = asArray(note && note.polygon).length;
            const text = note && note.text ? note.text : "(empty text)";
            return `Note ${index + 1} (${points} point${points === 1 ? "" : "s"}): ${text}`;
        })
        .join("\n\n");
}

class PostRevisionListControl extends events.EventTarget {
    constructor(hostNode, post) {
        super();
        this._hostNode = hostNode;
        this._post = post;
        this._revisions = [];
        this._offset = 0;
        this._total = 0;
        this._loading = false;
        this._hasMore = true;
        this._error = "";
        this._restoringRevisionId = null;
        this._tagCache = new Map();
        this._tagLookups = new Map();

        this._loadMore();
    }

    _formatTag(tagName) {
        const name = String(tagName);
        if (!this._tagCache.has(name)) {
            return escape(name);
        }

        const tag = this._tagCache.get(name);
        if (!tag || !tag.names || !tag.names.length) {
            return escape(name);
        }

        const targetName = tag.names[0];
        const href = uri.formatClientLink("posts", {
            query: uri.escapeTagName(targetName),
        });
        const className = misc.makeCssName(tag.category || "default", "tag");

        return `<a href="${escape(href)}" class="${escape(className)}">${escape(name)}</a>`;
    }

    _formatTags(value) {
        const names = asArray(value).map(String);
        return names.length
            ? names.map((name) => this._formatTag(name)).join(", ")
            : "None";
    }

    _formatListDiff(label, currentValue, olderValue, formatter) {
        const current = asArray(currentValue).map(String);
        const older = asArray(olderValue).map(String);
        const added = current.filter((value) => !older.includes(value));
        const removed = older.filter((value) => !current.includes(value));

        if (!added.length && !removed.length) {
            return "";
        }

        const parts = [];
        if (added.length) {
            parts.push(
                "+" + added.slice(0, 6).map(formatter).join(", +")
            );
            if (added.length > 6) {
                parts.push(`+${added.length - 6} more`);
            }
        }
        if (removed.length) {
            parts.push(
                "-" + removed.slice(0, 6).map(formatter).join(", -")
            );
            if (removed.length > 6) {
                parts.push(`-${removed.length - 6} more`);
            }
        }
        return `${escape(label)}: ${parts.join(" ")}`;
    }

    _formatSummary(revision, olderRevision) {
        const data = revision.data || {};
        const prefix = revision.restoredFromRevisionId
            ? `Restored from revision #${escape(revision.restoredFromRevisionId)}`
            : "";

        if (!olderRevision) {
            return [prefix, "Initial saved metadata"]
                .filter(Boolean)
                .join("; ");
        }

        const older = olderRevision.data || {};
        const changes = [];

        if (data.safety !== older.safety) {
            changes.push(
                `Safety: ${escape(asText(older.safety))} → ${escape(asText(data.safety))}`
            );
        }

        for (const [label, current, previous, formatter] of [
            ["Tags", data.tags, older.tags, (value) => this._formatTag(value)],
            ["Flags", data.flags, older.flags, escape],
            ["Relations", data.relations, older.relations, escape],
        ]) {
            const change = this._formatListDiff(
                label,
                current,
                previous,
                formatter
            );
            if (change) {
                changes.push(change);
            }
        }

        if (data.source !== older.source) {
            changes.push("Source changed");
        }
        if (data.description !== older.description) {
            changes.push("Description changed");
        }
        if (JSON.stringify(data.notes || []) !== JSON.stringify(older.notes || [])) {
            changes.push("Notes changed");
        }

        return [prefix, ...changes].filter(Boolean).join("; ") ||
            "No metadata changes";
    }

    _resolveTags(revisions) {
        const lookups = [];

        for (const revision of revisions) {
            for (const tagName of asArray((revision.data || {}).tags)) {
                const name = String(tagName);
                if (
                    this._tagCache.has(name) ||
                    this._tagLookups.has(name)
                ) {
                    continue;
                }

                const lookup = Tag.get(name).then(
                    (tag) => {
                        this._tagCache.set(name, tag);
                    },
                    () => {
                        this._tagCache.set(name, null);
                    }
                ).then(() => {
                    this._tagLookups.delete(name);
                });

                this._tagLookups.set(name, lookup);
                lookups.push(lookup);
            }
        }

        if (lookups.length) {
            Promise.all(lookups).then(() => this._render());
        }
    }

    _render() {
        views.replaceContent(
            this._hostNode,
            template({
                revisions: this._revisions,
                total: this._total,
                loading: this._loading,
                hasMore: this._hasMore,
                error: this._error,
                restoringRevisionId: this._restoringRevisionId,
                asText,
                formatList,
                formatRelations,
                formatNotes,
                formatTags: (value) => this._formatTags(value),
                formatSummary: (revision, olderRevision) =>
                    this._formatSummary(revision, olderRevision),
            })
        );

        for (const node of this._hostNode.querySelectorAll(".restore-revision")) {
            node.addEventListener("click", (event) => this._evtRestore(event));
        }

        const loadMoreNode = this._hostNode.querySelector(".load-more-revisions");
        if (loadMoreNode) {
            loadMoreNode.addEventListener("click", () => this._loadMore());
        }
    }

    _loadMore() {
        if (this._loading || !this._hasMore) {
            return;
        }

        this._loading = true;
        this._error = "";
        this._render();

        api.get(
            uri.formatApiLink("post", this._post.id, "revisions", {
                offset: this._offset,
                limit: PAGE_SIZE,
                fields: FIELDS,
            }),
            { force: true }
        ).then(
            (response) => {
                const results = asArray(response.results);
                this._revisions.push(...results);
                this._offset += results.length;
                this._total = Number(response.total) || 0;
                this._hasMore =
                    results.length > 0 && this._revisions.length < this._total;
                this._loading = false;
                this._render();
                this._resolveTags(results);
            },
            (error) => {
                this._loading = false;
                this._error = error.message || "Failed to load revision history.";
                this._render();
            }
        );
    }

    _evtRestore(event) {
        event.preventDefault();

        const revisionId = Number(event.currentTarget.dataset.revisionId);
        if (
            !Number.isSafeInteger(revisionId) ||
            this._restoringRevisionId !== null
        ) {
            return;
        }

        const confirmed = confirm(
            `Restore revision #${revisionId}?\n\n` +
            "This restores tags, safety, flags, source, description, relations, and notes.\n\n" +
            "Media, thumbnails, dimensions, checksums, and featured state remain current."
        );
        if (!confirmed) {
            return;
        }

        this._restoringRevisionId = revisionId;
        this._error = "";
        this._render();

        this._post.restoreRevision(revisionId).then(
            () => {
                this._revisions = [];
                this._offset = 0;
                this._total = 0;
                this._hasMore = true;
                this._restoringRevisionId = null;
                this._loadMore();
            },
            (error) => {
                this._restoringRevisionId = null;
                this._error = error.message || "Failed to restore revision.";
                this._render();
            }
        );
    }
}

module.exports = PostRevisionListControl;
