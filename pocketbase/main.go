package main

import (
	"log"
	"os"
	"strconv"
	"strings"

	_ "github.com/bunkbed-tech/fushigi/pocketbase/migrations"

	"github.com/pocketbase/pocketbase"
	"github.com/pocketbase/pocketbase/apis"
	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/pocketbase/plugins/migratecmd"
)

func main() {
	app := pocketbase.New()

	// loosely check if it was executed using "go run"
	isGoRun := strings.HasPrefix(os.Args[0], os.TempDir())

	// Run migrations if they exist
	migratecmd.MustRegister(app, app.RootCmd, migratecmd.Config{
		// enable auto creation of migration files when making collection changes in the Dashboard
		// (the isGoRun check is to enable it only during development)
		Automigrate: isGoRun,
	})

	configureAppSettings(app)

	app.OnServe().BindFunc(func(se *core.ServeEvent) error {
		// serves static files from the provided public dir (if exists)
		se.Router.GET("/{path...}", apis.Static(os.DirFS("./pb_public"), false))

		return se.Next()
	})

	if err := app.Start(); err != nil {
		log.Fatal(err)
	}
}

func configureAppSettings(app core.App) {
	settings := app.Settings()

	// Basic Info
	settings.Meta.AppName = os.Getenv("APP_NAME")
	settings.Meta.AppURL = os.Getenv("APP_URL")
	settings.Meta.SenderName = os.Getenv("SENDER_NAME")
	settings.Meta.SenderAddress = os.Getenv("SENDER_ADDRESS")

	// Turn on logs
	settings.Logs.MaxDays = 7
	settings.Logs.LogAuthId = true
	settings.Logs.LogIP = true

	// Use SMTP for sending users emails from my SenderAddress
	settings.SMTP.Enabled = true
	settings.SMTP.Host = os.Getenv("SMTP_HOST")
	if portStr := os.Getenv("SMTP_PORT"); portStr != "" {
		if port, err := strconv.Atoi(portStr); err == nil {
			settings.SMTP.Port = port
		}
	} // If it fails to read port and it's not set... what happens
	settings.SMTP.Username = os.Getenv("SMTP_EMAIL")
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
}
