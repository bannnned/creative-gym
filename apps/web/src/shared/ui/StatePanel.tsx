type StatePanelProps = {
  title: string;
  message?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
};

export function StatePanel({ title, message, action }: StatePanelProps) {
  return (
    <section className="state-panel" aria-live="polite">
      <h2>{title}</h2>
      {message ? <p>{message}</p> : null}
      {action ? (
        <button className="button secondary" type="button" onClick={action.onClick}>
          {action.label}
        </button>
      ) : null}
    </section>
  );
}
