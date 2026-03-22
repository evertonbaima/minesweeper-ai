import styled from 'styled-components'

const Wrapper = styled.div`
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background: #1a1a2e;
  font-family: 'Courier New', monospace;
  color: #e0e0e0;
`

const Title = styled.h1`
  font-size: 2rem;
  letter-spacing: 0.2em;
  color: #4ecca3;
`

function App() {
  return (
    <Wrapper>
      <Title>MINESWEEPER</Title>
    </Wrapper>
  )
}

export default App
