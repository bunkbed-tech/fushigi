package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
	"os"
)

func init() {
	m.Register(func(app core.App) error {
		// Create the initial super user
		adminEmail := os.Getenv("ADMIN_EMAIL")
		adminPassword := os.Getenv("ADMIN_PASSWORD")

		superusers, err := app.FindCollectionByNameOrId(core.CollectionNameSuperusers)
		if err != nil {
			return err
		}

		superusers.MFA.Enabled = true
		superusers.MFA.Duration = 1800 // 30 minutes
		superusers.OTP.Enabled = true
		superusers.OTP.Duration = 180 // 3 minutes

		if err := app.Save(superusers); err != nil {
			return err
		}

		record, _ := app.FindAuthRecordByEmail(core.CollectionNameSuperusers, adminEmail)
		if record == nil {
			record = core.NewRecord(superusers)
			record.Set("email", adminEmail)
			record.Set("password", adminPassword)
			if err := app.Save(record); err != nil {
				return err
			}
		}

		// Add in a demo user
		prodFlag := os.Getenv("IS_PROD")
		if prodFlag == "false" {
			users, err := app.FindCollectionByNameOrId("users")
			if err != nil {
				return err
			}
			record, _ := app.FindAuthRecordByEmail("users", "tester@example.com")
			if record == nil {
				record := core.NewRecord(users)
				record.Set("email", "tester@example.com")
				record.Set("password", "password123")
				record.Set("verified", true)
				if err := app.Save(record); err != nil {
					return err
				}
			}
		}

		return nil
	}, func(app core.App) error { // optional revert operation
		adminEmail := os.Getenv("ADMIN_EMAIL")
		record, _ := app.FindAuthRecordByEmail(core.CollectionNameSuperusers, adminEmail)
		if record != nil {
			return app.Delete(record)
		}
		record, _ = app.FindAuthRecordByEmail("users", "tester@example.com")
		if record != nil {
			return app.Delete(record)
		}
		return nil
	})
}
