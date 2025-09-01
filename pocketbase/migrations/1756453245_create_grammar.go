package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
	"github.com/pocketbase/pocketbase/tools/types"
)

func init() {
	m.Register(func(app core.App) error {
		collection := core.NewBaseCollection("grammar")

		collection.ViewRule = types.Pointer("@request.auth.id != '' && (user = @request.auth.id || user = null)")
		collection.ListRule = types.Pointer("@request.auth.id != '' && (user = @request.auth.id || user = null)")
		collection.CreateRule = types.Pointer("@request.auth.id != '' && @request.body.user = @request.auth.id")
		collection.UpdateRule = types.Pointer("@request.auth.id != '' && user = @request.auth.id && (@request.body.user:isset = false || @request.body.user = @request.auth.id)")
		collection.DeleteRule = types.Pointer("@request.auth.id != '' && user = @request.auth.id")

		usersCollection, err := app.FindCollectionByNameOrId("users")
		if err != nil {
			return err
		}
		collection.Fields.Add(&core.RelationField{
			Name:          "user",
			Required:      false,
			CascadeDelete: true,
			CollectionId:  usersCollection.Id,
		})

		languagesCollection, err := app.FindCollectionByNameOrId("languages")
		if err != nil {
			return err
		}
		collection.Fields.Add(&core.RelationField{
			Name:          "language",
			Required:      true,
			CascadeDelete: false,
			CollectionId:  languagesCollection.Id,
		})

		collection.Fields.Add(&core.TextField{
			Name:     "usage",
			Required: true,
		})

		collection.Fields.Add(&core.TextField{
			Name:     "meaning",
			Required: true,
		})

		collection.Fields.Add(&core.TextField{
			Name:     "context",
			Required: false,
		})

		collection.Fields.Add(&core.JSONField{
			Name:     "tags",
			Required: false,
		})

		collection.Fields.Add(&core.TextField{
			Name:     "notes",
			Required: false,
		})

		collection.Fields.Add(&core.TextField{
			Name:     "nuance",
			Required: false,
		})

		collection.Fields.Add(&core.JSONField{
			Name:     "examples",
			Required: false,
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

		err = app.Save(collection)
		if err != nil {
			return err
		}

		return nil
	}, func(app core.App) error { // optional revert operation
		collection, err := app.FindCollectionByNameOrId("grammar")
		if err != nil {
			return err
		}

		return app.Delete(collection)
	})
}
