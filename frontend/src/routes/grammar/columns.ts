import type { ColumnDef } from "@tanstack/table-core";
import { renderComponent } from "$lib/components/ui/data-table/index.js";
import DataTableActions from "./data-table-actions.svelte";

export type GrammarPoint = {
	id: number;
	context: string;
	usage: string;
	meaning: string;
	tags: string[];
};

export const columns: ColumnDef<GrammarPoint>[] = [
	{
		accessorKey: "level",
		header: "場合",
		size: 100,
	},
	{
		accessorKey: "usage",
		header: "使い方",
		size: 200,
	},
	{
		accessorKey: "meaning",
		header: "意味",
		size: 300,
	},
	{
		accessorKey: "tags",
		header: "Tags",
		size: 150,
	},
	{
		id: "actions",
		size: 50,
		cell: ({ row }) => {
			// What else can I do here? Delete call? view more stuff?
			// I feel like I want a view more info, view in entries button
			return renderComponent(DataTableActions, { id: row.original.id });
		},
	},
];
