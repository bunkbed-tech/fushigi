package migrations

import (
	"github.com/pocketbase/pocketbase/core"
	m "github.com/pocketbase/pocketbase/migrations"
	"os"
)

func init() {
	m.Register(func(app core.App) error {
		// --- App Settings ---
		settings := app.Settings()

		// Basic Info
		settings.Meta.AppName = "Fushigi"
		settings.Meta.AppURL = "https://fushigi.bunkbed.tech"
		settings.Meta.SenderName = "Fushigi App"
		settings.Meta.SenderAddress = "info@bunkbed.tech"

		// Turn on logs
		settings.Logs.MaxDays = 7
		settings.Logs.LogAuthId = true
		settings.Logs.LogIP = true

		// Use SMTP for sending users emails from my SenderAddress
		settings.SMTP.Enabled = true
		settings.SMTP.Host = "smtp.gmail.com"
		settings.SMTP.Port = 587
		settings.SMTP.Username = os.Getenv("SMTP_USERNAME")
		settings.SMTP.Password = os.Getenv("SMTP_PASSWORD")
		settings.SMTP.TLS = true

		// Protect against the api getting hammered (idk good values)
		settings.RateLimits.Enabled = true
		settings.RateLimits.Rules = []core.RateLimitRule{
			{Label: "*:auth", Duration: 60, MaxRequests: 5},
			{Label: "*:create", Duration: 60, MaxRequests: 10},
			{Label: "*:update", Duration: 60, MaxRequests: 10},
			{Label: "/api/", Duration: 60, MaxRequests: 100},
		}

		// Periodic backups
		settings.Backups.Cron = "0 0 * * 0" // run every sunday at midnight
		settings.Backups.CronMaxKeep = 3    // keep three weeks worth

		if err := app.Save(settings); err != nil {
			return err
		}

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
