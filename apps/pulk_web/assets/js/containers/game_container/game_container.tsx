import React from "react";
import { styled } from "goober";

import { TetrisField } from "../tetris_field";
import { BoardView, LoadingSpinner } from "../../components";
import { useRoom } from "./hooks";

const Container = styled("div")`
  display: flex;
  height: 100%;
`;

const PlayerColumn = styled("div")`
  display: flex;
  justify-content: center;
  align-items: center;
  width: 40%;
`;

const ComptetitorsColumn = styled<{ side?: "left" | "right" }>("div")`
  display: flex;
  width: 40%;
  padding: 16px;
  gap: 8px;
  justify-content: ${(props) =>
    props.side === "left" ? "flex-end" : "flex-start"};
`;

interface Props {
  roomId: string;
}

const ViewContainer = styled("div")``;

export const GameContainer: React.FunctionComponent<Props> = ({ roomId }) => {
  const { setMatrix, error, player, otherPlayers, isLoading } = useRoom({
    roomId,
  });

  if (isLoading) {
    return <LoadingSpinner />;
  }

  if (error !== undefined) {
    return (
      <Container>
        <div>Failed {error}</div>
      </Container>
    );
  }

  return (
    <Container>
      <ComptetitorsColumn side={"left"}>
        {Array.from(otherPlayers.entries()).map(
          ([playerId, matrix], idx) =>
            idx % 2 === 0 && (
              <ViewContainer key={playerId}>
                <BoardView matrix={matrix} />
              </ViewContainer>
            )
        )}
      </ComptetitorsColumn>
      <PlayerColumn>
        <TetrisField matrix={player.matrix} setMatrix={setMatrix} />
      </PlayerColumn>
      <ComptetitorsColumn>
        {Array.from(otherPlayers.entries()).map(
          ([playerId, matrix], idx) =>
            idx % 2 !== 0 && (
              <ViewContainer key={playerId}>
                <BoardView matrix={matrix} />
              </ViewContainer>
            )
        )}
      </ComptetitorsColumn>
    </Container>
  );
};
