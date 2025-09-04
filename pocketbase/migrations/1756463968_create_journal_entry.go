package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
	"github.com/pocketbase/pocketbase/tools/types"
)

func init() {
	m.Register(func(app core.App) error {
		collection := core.NewBaseCollection("journal_entry")

		collection.ViewRule = types.Pointer("@request.auth.id != '' && (user = @request.auth.id || is_private = false)")
		collection.ListRule = types.Pointer("@request.auth.id != '' && (user = @request.auth.id || is_private = false)")
		collection.CreateRule = types.Pointer("@request.auth.id != '' && @request.body.user = @request.auth.id")
		collection.UpdateRule = types.Pointer("@request.auth.id != '' && user = @request.auth.id && (@request.body.user:isset = false || @request.body.user = @request.auth.id)")
		collection.DeleteRule = types.Pointer("@request.auth.id != '' && user = @request.auth.id")

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

		collection.Fields.Add(&core.TextField{
			Name:     "title",
			Required: true,
		})

		collection.Fields.Add(&core.TextField{
			Name:     "content",
			Required: true,
		})

		collection.Fields.Add(&core.BoolField{
			Name: "is_private",
			//Required: true, this does not do what you think it does...
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

		collection.AddIndex("idx_journal_entry_by_user", false, "user", "")

		err = app.Save(collection)
		if err != nil {
			return err
		}

		return nil
	}, func(app core.App) error { // optional revert operation
		collection, err := app.FindCollectionByNameOrId("journal_entry")
		if err != nil {
			return err
		}

		return app.Delete(collection)
	})
}
