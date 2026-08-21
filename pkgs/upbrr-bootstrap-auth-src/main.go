// SPDX-License-Identifier: GPL-2.0-or-later
// upbrr-bootstrap-auth generates a valid web-auth.json file for upbrr.
// Built against upbrr's internal/authmaterial package so the Argon2id parameters
// and record schema match the running server exactly.

package main

import (
	"bytes"
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/autobrr/upbrr/internal/authmaterial"
)

func main() {
	var (
		username    = flag.String("username", "", "admin username")
		password    = flag.String("password", "", "admin password (min 12 chars)")
		browseRoots = flag.String("browse-roots", "", "comma-separated browse roots")
		output      = flag.String("output", "", "destination path for web-auth.json (mode 0600)")
		createdAt   = flag.String("created-at", "", "RFC3339 timestamp (default: now UTC)")
	)
	flag.Parse()

	if strings.TrimSpace(*username) == "" {
		fail("--username is required")
	}
	if strings.TrimSpace(*password) == "" {
		fail("--password is required")
	}
	if strings.TrimSpace(*output) == "" {
		fail("--output is required")
	}
	if len(*password) < authmaterial.AuthPasswordMinLength {
		fail(fmt.Sprintf("--password must be at least %d characters", authmaterial.AuthPasswordMinLength))
	}

	var roots []string
	if s := strings.TrimSpace(*browseRoots); s != "" {
		for _, r := range strings.Split(s, ",") {
			r = strings.TrimSpace(r)
			if r != "" {
				roots = append(roots, r)
			}
		}
	}

	hash, err := authmaterial.HashPassword(*password)
	if err != nil {
		fail(fmt.Sprintf("hash password: %v", err))
	}
	seed, err := authmaterial.GenerateSeed()
	if err != nil {
		fail(fmt.Sprintf("generate seed: %v", err))
	}

	createdTime := time.Now().UTC()
	if s := strings.TrimSpace(*createdAt); s != "" {
		t, err := time.Parse(time.RFC3339, s)
		if err != nil {
			fail(fmt.Sprintf("parse --created-at: %v", err))
		}
		createdTime = t.UTC()
	}

	record := authmaterial.Record{
		Username:          strings.TrimSpace(*username),
		PasswordHash:      hash,
		EncryptionKeySeed: seed,
		BrowseRoot:        joinBrowseRoots(roots),
		CreatedAt:         createdTime,
	}

	if err := writeAuthFile(*output, record); err != nil {
		fail(fmt.Sprintf("write: %v", err))
	}
	fmt.Printf("wrote %s (mode 0600)\n", *output)
}

// joinBrowseRoots encodes roots the same way upbrr does (CSV with one record
// per line). Single-root values pass through with no surrounding quotes.
func joinBrowseRoots(roots []string) string {
	if len(roots) == 0 {
		return ""
	}
	var buf bytes.Buffer
	w := csv.NewWriter(&buf)
	if err := w.Write(roots); err != nil {
		return strings.Join(roots, ", ")
	}
	w.Flush()
	if err := w.Error(); err != nil {
		return strings.Join(roots, ", ")
	}
	return strings.TrimRight(buf.String(), "\r\n")
}

func writeAuthFile(path string, record authmaterial.Record) error {
	data, err := json.MarshalIndent(record, "", "  ")
	if err != nil {
		return fmt.Errorf("marshal: %w", err)
	}

	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return fmt.Errorf("mkdir: %w", err)
	}
	tmp, err := os.CreateTemp(dir, filepath.Base(path)+".tmp-*")
	if err != nil {
		return fmt.Errorf("create temp: %w", err)
	}
	tmpPath := tmp.Name()
	if _, err := tmp.Write(data); err != nil {
		_ = tmp.Close()
		_ = os.Remove(tmpPath)
		return fmt.Errorf("write temp: %w", err)
	}
	if err := tmp.Sync(); err != nil {
		_ = tmp.Close()
		_ = os.Remove(tmpPath)
		return fmt.Errorf("sync temp: %w", err)
	}
	if err := tmp.Close(); err != nil {
		_ = os.Remove(tmpPath)
		return fmt.Errorf("close temp: %w", err)
	}
	if err := os.Chmod(tmpPath, 0o600); err != nil {
		_ = os.Remove(tmpPath)
		return fmt.Errorf("chmod: %w", err)
	}
	if err := os.Rename(tmpPath, path); err != nil {
		_ = os.Remove(tmpPath)
		return fmt.Errorf("rename: %w", err)
	}
	return nil
}

func fail(msg string) {
	fmt.Fprintln(os.Stderr, "error:", msg)
	os.Exit(1)
}
