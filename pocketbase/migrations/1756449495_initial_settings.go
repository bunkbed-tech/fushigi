package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
)

func init() {
	m.Register(func(app core.App) error {
		// --- App Settings ---
		settings := app.Settings()

		settings.Meta.AppName = "Fushigi"
		settings.Meta.AppURL = "https://fushigi.bunkbed.tech"
		settings.Meta.SenderName = "Fushigi App"
		settings.Meta.SenderAddress = "fushigi-noreply@bunkbed.tech"
		//settings.Meta.HideControls = true

		//settings.Logs.MaxDays = 7
		//settings.Logs.LogAuthId = true
		//settings.Logs.LogIP = true

		//settings.SMTP.Enabled = true
		//settings.SMTP.Host = "1.2.3.4"
		//settings.SMTP.Port = 1234

		if err := app.Save(settings); err != nil {
			return err
		}

		// Create initial super user for dev testing
		superusers, err := app.FindCollectionByNameOrId(core.CollectionNameSuperusers)
		if err != nil {
			return err
		}

		// check if superuser already exists
		record, _ := app.FindAuthRecordByEmail(core.CollectionNameSuperusers, "tester@example.com")
		if record == nil {
			record = core.NewRecord(superusers)
			record.Set("email", "tester@example.com")
			record.Set("password", "password123")
			if err := app.Save(record); err != nil {
				return err
			}
		}

		return nil
	}, func(app core.App) error { // optional revert operation
		record, _ := app.FindAuthRecordByEmail(core.CollectionNameSuperusers, "tester@example.com")
		if record != nil {
			return app.Delete(record)
		}
		return nil
	})
}
