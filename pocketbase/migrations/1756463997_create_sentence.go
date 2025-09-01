package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
	"github.com/pocketbase/pocketbase/tools/types"
)

func init() {
	m.Register(func(app core.App) error {
		collection := core.NewBaseCollection("sentence")

		collection.ViewRule = types.Pointer("@request.auth.id != '' && user = @request.auth.id")
		collection.ListRule = types.Pointer("@request.auth.id != '' && user = @request.auth.id")
		collection.CreateRule = types.Pointer("@request.auth.id != '' && @request.body.user = @request.auth.id")
		collection.UpdateRule = types.Pointer("@request.auth.id != '' && user = @request.auth.id && (@request.body.user:isset = false || @request.body.user = @request.auth.id)")

		usersCollection, err := app.FindCollectionByNameOrId("users")
		if err != nil {
			return err
		}
		collection.Fields.Add(&core.RelationField{
			Name:          "user",
			Required:      true,
			CascadeDelete: true,
			CollectionId:  usersCollection.Id,
		})

		journalsCollection, err := app.FindCollectionByNameOrId("journal_entry")
		if err != nil {
			return err
		}
		collection.Fields.Add(&core.RelationField{
			Name:          "journal_entry",
			Required:      true,
			CascadeDelete: true,
			CollectionId:  journalsCollection.Id,
		})

		grammarCollection, err := app.FindCollectionByNameOrId("grammar")
		if err != nil {
			return err
		}
		collection.Fields.Add(&core.RelationField{
			Name:          "grammar",
			Required:      true,
			CascadeDelete: false,
			CollectionId:  grammarCollection.Id,
		})

		collection.Fields.Add(&core.TextField{
			Name:     "content",
			Required: true,
		})

		collection.Fields.Add(&core.AutodateField{
			Name:     "created",
			OnCreate: true,
		})

		collection.Fields.Add(&core.AutodateField{
			Name:     "updated",
			OnCreate: true,
			OnUpdate: true,
		})

		collection.AddIndex("idx_sentence_by_user", false, "user", "")
		collection.AddIndex("idx_sentence_by_journal_entry", false, "journal_entry", "")
		collection.AddIndex("idx_sentence_by_grammar", false, "grammar", "")

		err = app.Save(collection)
		if err != nil {
			return err
		}

		return nil
	}, func(app core.App) error { // optional revert operation
		collection, err := app.FindCollectionByNameOrId("sentence")
		if err != nil {
			return err
		}

		return app.Delete(collection)
	})
}
