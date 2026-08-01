package auth

import (
	"fmt"
	"mime"
	"net"
	"net/smtp"
	"strings"
)

type Mailer interface {
	SendEmailConfirmation(to string, confirmationURL string) error
}

type SMTPMailer struct {
	host     string
	port     string
	username string
	password string
	from     string
}

func NewSMTPMailer(host, port, username, password, from string) *SMTPMailer {
	return &SMTPMailer{
		host:     host,
		port:     port,
		username: username,
		password: password,
		from:     from,
	}
}

func (m *SMTPMailer) SendEmailConfirmation(to string, confirmationURL string) error {
	address := net.JoinHostPort(m.host, m.port)
	var auth smtp.Auth
	if m.username != "" {
		auth = smtp.PlainAuth("", m.username, m.password, m.host)
	}

	subject := "Подтвердите почту — Creative Gym"
	body := strings.Join([]string{
		"Подтвердите почту, чтобы получать очки за призовые места.",
		"",
		confirmationURL,
		"",
		"Ссылка действует 30 минут. Если вы не запрашивали письмо, просто проигнорируйте его.",
	}, "\r\n")
	message := []byte(fmt.Sprintf(
		"From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n%s\r\n",
		m.from,
		to,
		mime.QEncoding.Encode("UTF-8", subject),
		body,
	))

	if err := smtp.SendMail(address, auth, m.from, []string{to}, message); err != nil {
		return fmt.Errorf("send confirmation email: %w", err)
	}
	return nil
}
