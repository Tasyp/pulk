import React from "react";

interface Props {
  name: string;
}

const App: React.FC<Props> = (props: Props) => {
  const name = props.name;
  return (
    <section className="phx-hero">
      <h1>Welcome to {name} with TypeScript and React!</h1>
      <p>Peace-of-mind from prototype to production</p>
    </section>
  );
};

export default App;
