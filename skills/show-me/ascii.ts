import { renderMermaidAscii } from 'beautiful-mermaid@1.1.3'

console.log(renderMermaidAscii(await Bun.stdin.text()))
