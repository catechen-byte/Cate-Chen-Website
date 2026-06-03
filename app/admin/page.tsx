"use client";

import { FormEvent, useEffect, useState } from "react";
import { ADMIN_EMAIL, createClient, isSupabaseConfigured } from "@/lib/supabase/client";

type Draft = {
  id: string;
  title: string;
  kind: string;
  body: string;
  updated_at: string;
};

export default function AdminPage() {
  const [email, setEmail] = useState("");
  const [sessionEmail, setSessionEmail] = useState<string | null>(null);
  const [drafts, setDrafts] = useState<Draft[]>([]);
  const [title, setTitle] = useState("");
  const [kind, setKind] = useState("blog");
  const [body, setBody] = useState("");
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!isSupabaseConfigured()) return;
    const supabase = createClient();
    if (!supabase) return;

    supabase.auth.getSession().then(({ data }) => {
      setSessionEmail(data.session?.user.email ?? null);
    });
  }, []);

  async function signIn(event: FormEvent) {
    event.preventDefault();
    setMessage(null);
    const supabase = createClient();
    if (!supabase) return;

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/admin` },
    });

    setMessage(error ? error.message : "Check your email for a magic link.");
  }

  async function loadDrafts() {
    const supabase = createClient();
    if (!supabase || !sessionEmail) return;

    if (ADMIN_EMAIL && sessionEmail !== ADMIN_EMAIL) {
      setMessage("This account is not authorized for admin access.");
      return;
    }

    const { data, error } = await supabase
      .from("draft_posts")
      .select("id, title, kind, body, updated_at")
      .order("updated_at", { ascending: false });

    if (error) {
      setMessage(error.message);
      return;
    }

    setDrafts(data ?? []);
  }

  async function saveDraft(event: FormEvent) {
    event.preventDefault();
    const supabase = createClient();
    if (!supabase || !sessionEmail) return;

    const { data: userData } = await supabase.auth.getUser();
    const user = userData.user;
    if (!user) return;

    const { error } = await supabase.from("draft_posts").insert({
      user_id: user.id,
      title,
      kind,
      body,
    });

    setMessage(error ? error.message : "Draft saved.");
    if (!error) {
      setTitle("");
      setBody("");
      loadDrafts();
    }
  }

  function exportMdx(draft: Draft) {
    const slug = draft.title.toLowerCase().replace(/[^a-z0-9]+/g, "-");
    const mdx = `---\ntitle: "${draft.title}"\ndate: "${new Date().toISOString().slice(0, 10)}"\nsummary: ""\ntags: []\ndraft: true\n---\n\n${draft.body}`;
    navigator.clipboard.writeText(mdx);
    setMessage(`Copied MDX for ${slug}.md to clipboard — paste into content/${draft.kind}/`);
  }

  if (!isSupabaseConfigured()) {
    return (
      <div className="mx-auto max-w-2xl px-6 py-16">
        <h1 className="text-3xl font-semibold">Admin</h1>
        <p className="mt-4 text-[var(--color-muted)]">
          Supabase is not configured. Add <code>NEXT_PUBLIC_SUPABASE_URL</code> and{" "}
          <code>NEXT_PUBLIC_SUPABASE_ANON_KEY</code> to enable private drafting.
        </p>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-2xl px-6 py-16">
      <h1 className="text-3xl font-semibold">Admin drafts</h1>
      <p className="mt-2 text-sm text-[var(--color-muted)]">
        Magic-link login · drafts stored in Supabase · export to repo MDX when ready.
      </p>

      {!sessionEmail ? (
        <form onSubmit={signIn} className="mt-8 space-y-4">
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="your@email.com"
            className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] px-4 py-2"
          />
          <button type="submit" className="rounded-lg bg-[var(--color-accent)] px-4 py-2 text-white">
            Send magic link
          </button>
        </form>
      ) : (
        <>
          <p className="mt-6 text-sm">Signed in as {sessionEmail}</p>
          <button
            type="button"
            onClick={loadDrafts}
            className="mt-2 text-sm text-[var(--color-accent)] underline"
          >
            Refresh drafts
          </button>

          <form onSubmit={saveDraft} className="mt-8 space-y-4">
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Title"
              required
              className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] px-4 py-2"
            />
            <select
              value={kind}
              onChange={(e) => setKind(e.target.value)}
              className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] px-4 py-2"
            >
              <option value="blog">blog</option>
              <option value="projects">projects</option>
              <option value="research">research</option>
            </select>
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              placeholder="Markdown body"
              rows={8}
              required
              className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-card)] px-4 py-2"
            />
            <button type="submit" className="rounded-lg bg-[var(--color-accent)] px-4 py-2 text-white">
              Save draft
            </button>
          </form>

          <ul className="mt-8 space-y-4">
            {drafts.map((draft) => (
              <li key={draft.id} className="rounded-lg border border-[var(--color-border)] p-4">
                <p className="font-medium">{draft.title}</p>
                <p className="text-xs text-[var(--color-muted)]">
                  {draft.kind} · {new Date(draft.updated_at).toLocaleString()}
                </p>
                <button
                  type="button"
                  onClick={() => exportMdx(draft)}
                  className="mt-2 text-sm text-[var(--color-accent)] underline"
                >
                  Export MDX to clipboard
                </button>
              </li>
            ))}
          </ul>
        </>
      )}

      {message ? <p className="mt-6 text-sm text-[var(--color-muted)]">{message}</p> : null}
    </div>
  );
}
