package auth

import "testing"

func TestNormalizeEmail(t *testing.T) {
	email, err := normalizeEmail("  Person@Example.COM ")
	if err != nil {
		t.Fatalf("normalizeEmail() error = %v", err)
	}
	if email != "person@example.com" {
		t.Fatalf("email = %q, want person@example.com", email)
	}
}

func TestNormalizeEmailRejectsDisplayName(t *testing.T) {
	if _, err := normalizeEmail("Person <person@example.com>"); err == nil {
		t.Fatal("normalizeEmail() error = nil, want invalid email")
	}
}

func TestMaskEmail(t *testing.T) {
	if got := maskEmail("person@example.com"); got != "p••••@example.com" {
		t.Fatalf("maskEmail() = %q", got)
	}
}
