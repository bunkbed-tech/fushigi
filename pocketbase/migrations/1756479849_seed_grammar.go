package migrations

import (
	_ "embed"
	"encoding/json"
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

//go:embed data/grammar.json
var grammarJSON []byte

type Example struct {
	Japanese string `json:"japanese"`
	English  string `json:"english"`
}

type Grammar struct {
	Usage    string    `json:"usage"`
	Meaning  string    `json:"meaning"`
	Context  string    `json:"context"`
	Tags     []string  `json:"tags"`
	Notes    string    `json:"notes"`
	Nuance   string    `json:"nuance"`
	Examples []Example `json:"examples"`
}

type GrammarData struct {
	Grammar []Grammar `json:"grammar"`
}

func init() {
	m.Register(func(app core.App) error {
		// Find Japanese language
		languagesCollection, err := app.FindCollectionByNameOrId("languages")
		if err != nil {
			return err
		}

		japaneseRecord, err := app.FindFirstRecordByFilter(
			languagesCollection.Id,
			"name = 'Japanese'",
		)
		if err != nil {
			return err
		}

		// Load embedded grammar data
		var grammarData GrammarData
		if err := json.Unmarshal(grammarJSON, &grammarData); err != nil {
			return err
		}

		grammarCollection, err := app.FindCollectionByNameOrId("grammar")
		if err != nil {
			return err
		}

		// Create grammar records
		for _, grammar := range grammarData.Grammar {
			record := core.NewRecord(grammarCollection)
			record.Set("language", japaneseRecord.Id)
			record.Set("usage", grammar.Usage)
			record.Set("meaning", grammar.Meaning)
			record.Set("context", grammar.Context)
			record.Set("notes", grammar.Notes)
			record.Set("nuance", grammar.Nuance)
			record.Set("tags", grammar.Tags)
			record.Set("examples", grammar.Examples)

			if err := app.Save(record); err != nil {
				return err
			}
		}

		return nil
	}, func(app core.App) error {
		// Skip revert for now
		return nil
	})
}
