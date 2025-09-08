package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
	"github.com/pocketbase/pocketbase/tools/types"
)

func init() {
	m.Register(func(app core.App) error {
		collection := core.NewBaseCollection("srs")

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

		grammarCollection, err := app.FindCollectionByNameOrId("grammar")
		if err != nil {
			return err
		}
		collection.Fields.Add(&core.RelationField{
			Name:          "grammar",
			Required:      true,
			CascadeDelete: true,
			CollectionId:  grammarCollection.Id,
		})

		collection.Fields.Add(&core.NumberField{
			Name:     "ease_factor",
			Required: true,
		})

		collection.Fields.Add(&core.NumberField{
			Name:     "interval_days",
			Required: true,
		})

		collection.Fields.Add(&core.NumberField{
			Name:     "repetition",
			Required: true,
		})

		collection.Fields.Add(&core.DateField{
			Name: "last_reviewed",
		})

		collection.Fields.Add(&core.AutodateField{
			Name:     "due_date",
			OnCreate: true,
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

		collection.AddIndex("idx_srs_by_grammar_per_user", true, "user, grammar", "")
		collection.AddIndex("idx_srs_by_user_due", false, "user, due_date", "")
		collection.AddIndex("idx_srs_by_user", false, "user", "")

		err = app.Save(collection)
		if err != nil {
			return err
		}

		return nil
	}, func(app core.App) error { // optional revert operation
		collection, err := app.FindCollectionByNameOrId("srs")
		if err != nil {
			return err
		}

		return app.Delete(collection)
	})
}
