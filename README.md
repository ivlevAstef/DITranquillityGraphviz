# DITranquillity Graphviz
Небольшая отдельная библиотечка. Используя возможности библиотеки [DITranquillity](https://github.com/ivlevAstef/DITranquillity) позволяет создать файл формата [graphviz](https://graphviz.org/about/), для возможности визуализации графа зависимостей.


для создания картинки графа из консоли:
`dot -Tpdf dependency_graph.dot -o DependencyGraph.pdf`

перед этим надо поставить graphviz:
`brew install graphviz`
