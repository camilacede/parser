# Parser

Aplicación de consola desarrollada en Dart que realiza el análisis léxico y sintáctico de consultas mediante un lenguaje de consulta personalizado.

El programa procesa una consulta escrita en un archivo de texto, identifica sus componentes léxicos y verifica que cumpla con las reglas gramaticales definidas.

## Funcionalidades

- **Análisis léxico:** identifica palabras reservadas, números, cadenas de texto y operadores.
- **Análisis sintáctico:** valida la estructura de las consultas.
- **Validación de condiciones:** reconoce operadores de comparación, condiciones lógicas y expresiones como `ESTA ENTRE`, `CONTIENE` y `EMPIEZA CON`.
- **Resultado:** indica si la consulta cumple con la sintaxis establecida.

## Tecnologías utilizadas

- Dart
- dart:io

## Estructura del proyecto

```text
parser/
├── lib/
│   └── main.dart
├── consulta.sql
└── README.md
```

## Ejecución

1. Tener instalado el SDK de Dart.
2. Abrir una terminal en la carpeta principal del proyecto.
3. Ejecutar el siguiente comando:

   ```bash
   dart run lib/main.dart
   ```

El programa leerá automáticamente el archivo `consulta.sql` y mostrará el resultado del análisis sintáctico en la consola.
