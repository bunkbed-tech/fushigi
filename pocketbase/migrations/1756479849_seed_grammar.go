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
	ID       string            `json:"id"`
	Language string            `json:"language"`
	Usage    string            `json:"usage"`
	Meaning  string            `json:"meaning"`
	Context  []string          `json:"context"`
	Level    string            `json:"level"`
	Variant  string            `json:"variant"`
	Notes    string            `json:"notes"`
	Examples []Example         `json:"examples"`
	Forms    map[string]string `json:"forms"`
}

func init() {
	m.Register(func(app core.App) error {
		// Parse the category-based JSON structure
		var grammarData map[string][]Grammar
		if err := json.Unmarshal(grammarJSON, &grammarData); err != nil {
			return err
		}

		grammarCollection, err := app.FindCollectionByNameOrId("grammar")
		if err != nil {
			return err
		}

		// Iterate through all categories and their grammar items
		for category, grammars := range grammarData {
			for _, grammar := range grammars {
				record := core.NewRecord(grammarCollection)
				record.Set("id", grammar.ID)
				record.Set("language", grammar.Language)
				record.Set("usage", grammar.Usage)
				record.Set("meaning", grammar.Meaning)
				record.Set("context", grammar.Context)
				record.Set("level", grammar.Level)
				record.Set("variant", grammar.Variant)
				record.Set("notes", grammar.Notes)
				record.Set("examples", grammar.Examples)
				record.Set("forms", grammar.Forms)
				record.Set("tags", []string{category})

				if err := app.Save(record); err != nil {
					return err
				}
			}
		}

		return nil
	}, func(app core.App) error {
		// Skip revert for now
		return nil
	})
}
