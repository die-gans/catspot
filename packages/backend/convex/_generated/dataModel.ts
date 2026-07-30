/**
 * Generated type helpers for the Catspot Convex backend.
 *
 * These are normally produced by `npx convex codegen`. They are hand-written
 * here only because the deployment is not configured yet (no credentials).
 * They will be replaced by the real generated files once `npx convex dev`
 * is run against a project.
 */
import type { DataModelFromSchemaDefinition, DocumentByName } from "convex/server";
import schema from "../schema.js";

export type DataModel = DataModelFromSchemaDefinition<typeof schema>;
export type Doc<TableName extends keyof DataModel> = DocumentByName<DataModel, TableName>;
