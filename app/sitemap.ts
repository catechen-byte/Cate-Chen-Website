import type { MetadataRoute } from "next";
import { getAllContent } from "@/lib/content";

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";

export default function sitemap(): MetadataRoute.Sitemap {
  const staticRoutes = ["", "/about", "/projects", "/research", "/blog", "/contact"].map((path) => ({
    url: `${siteUrl}${path}`,
    lastModified: new Date(),
  }));

  const projects = getAllContent("projects").map((item) => ({
    url: `${siteUrl}/projects/${item.slug}`,
    lastModified: new Date(item.date),
  }));

  const research = getAllContent("research").map((item) => ({
    url: `${siteUrl}/research/${item.slug}`,
    lastModified: new Date(item.date),
  }));

  const blog = getAllContent("blog").map((item) => ({
    url: `${siteUrl}/blog/${item.slug}`,
    lastModified: new Date(item.date),
  }));

  return [...staticRoutes, ...projects, ...research, ...blog];
}
