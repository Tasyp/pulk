import React from 'react'
import { styled } from 'goober'

import { TetrisField } from '../tetris_field'
import { BoardView } from '../../components'
import { getTestMatrix } from '../../lib/matrix'

interface Props {

}

const Container = styled("div")`
  display: flex;
  height: 100%;
`

const PlayerColumn = styled("div")`
  display: flex;
  justify-content: center;
  align-items: center;
  width: 40%;
`

const ComptetitorsColumn = styled<{ side?: "left" | "right" }>("div")`
  display: flex;
  width: 40%;
  padding: 16px;
  gap: 8px;
  justify-content: ${(props) => props.side === 'left' ? 'flex-end' : 'flex-start'};
`

const ViewContainer = styled("div")``

export const GameContainer: React.FunctionComponent<Props> = () => {
  return (
    <Container>
      <ComptetitorsColumn side={"left"}>
        <ViewContainer>
          <BoardView matrix={getTestMatrix()} />
        </ViewContainer>
      </ComptetitorsColumn>
      <PlayerColumn>
        <TetrisField />
      </PlayerColumn>
      <ComptetitorsColumn>
        <ViewContainer>
          <BoardView matrix={getTestMatrix()} />
        </ViewContainer>
      </ComptetitorsColumn>
    </Container>
  )
}
