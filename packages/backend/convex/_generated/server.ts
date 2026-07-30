/**
 * Generated server wrappers for the Catspot Convex backend.
 *
 * These are normally produced by `npx convex codegen`. They are hand-written
 * here only because the deployment is not configured yet (no credentials).
 * They will be replaced by the real generated files once `npx convex dev`
 * is run against a project.
 */
import type { DataModel } from "./dataModel.js";
import {
  actionGeneric,
  httpActionGeneric,
  internalMutationGeneric,
  mutationGeneric,
  queryGeneric,
} from "convex/server";
import type {
  ActionBuilder,
  HttpActionBuilder,
  MutationBuilder,
  QueryBuilder,
} from "convex/server";

export const query: QueryBuilder<DataModel, "public"> = queryGeneric as QueryBuilder<DataModel, "public">;
export const mutation: MutationBuilder<DataModel, "public"> = mutationGeneric as MutationBuilder<DataModel, "public">;
export const internalMutation: MutationBuilder<DataModel, "internal"> = internalMutationGeneric as MutationBuilder<DataModel, "internal">;
export const action: ActionBuilder<DataModel, "public"> = actionGeneric as ActionBuilder<DataModel, "public">;
export const httpAction: HttpActionBuilder = httpActionGeneric;
