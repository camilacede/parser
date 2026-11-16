/* Proyecto 1 LDP

Objeto de estudio:
<select> ::= SELECCIONA [TODOS | PRIMEROS <num> [%] | ULTIMOS <num> [%]] (* | <val> {, <val>}*) DE <cad> {, <cad>}* [DONDE <condicion>] [ORDENADO POR <orden>]
<cad> ::= <palabra> | “<palabra>”
<palabra> ::= <letra> {<letra> | <digito>}
<letra> ::= a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z
<num> ::= <digito> {<digito>}*
<digito> ::= 0|1|2|3|4|5|6|7|8|9
<val> ::= <num> | <cad>
<orden> ::= (<cad> | <num>) (ASC | DESC)
<condicion> ::= <val> <op> <val> | <val> [NO] ES NULO | <val> [NO] EMPIEZA CON <val> | <val> [NO] CONTIENE <val> | <val> [NO] ESTA ENTRE <val> Y <val> | <val> [NO] ESTA DENTRO DE (<val> {, <val>}*) | ‘(‘ <condicion> ‘)’ | NO <condicion> | <condicion> Y <condicion> | <condicion> O <condicion>
<op> ::= < | <= | !< | > | >= | !> | = | != | <>
*/

import 'dart:io';
// Esta clase representa el análisis léxico: convierte el texto fuente en una lista de tokens
class AnalizadorLexico {
  final String entrada; // Texto de entrada que contiene la consulta SQL
  int posicion = 0; // Puntero actual dentro de la cadena

  AnalizadorLexico(this.entrada); // Constructor que recibe la entrada

  // Este método recorre la entrada carácter por carácter y arma la lista de tokens.
  List<String> obtenerTokens() {
    List<String> listaTokens = [];
    while (posicion < entrada.length) {
      final caracter = entrada[posicion];
      // Ignora los espacios
      if (esEspacio(caracter)) {
        posicion++;
        // Si es una letra, intenta leer una palabra
      } else if (esLetra(caracter)) {
        listaTokens.add(leerPalabra());
        // Si es un número, verifica si es un número solo o uno seguido por %
      } else if (esDigito(caracter)) {
        listaTokens.add(leerNumeroOPorcentaje());
        // Si es una comilla doble, se trata de una cadena
      } else if (caracter == '"') {
        listaTokens.add(leerCadena());
        // Si es un símbolo de comparación, lo extrae como token
      } else if (esSimbolo(caracter)) {
        listaTokens.add(leerSimbolo());
      } else {
        // Si no coincide con nada, se ignora
        posicion++;
      }
    }
    return listaTokens;
  }
  // Verifica si un carácter es un espacio o salto de línea/tabulación
  bool esEspacio(String caracter) =>
      caracter == ' ' || caracter == '\n' || caracter == '\r' || caracter == '\t';
  // Verifica si un carácter es una letra entre a y z (mayúscula o minúscula)
  bool esLetra(String caracter) =>
      caracter.toLowerCase().compareTo('a') >= 0 && caracter.toLowerCase().compareTo('z') <= 0;
  // Verifica si un carácter es un dígito del 0 al 9
  bool esDigito(String caracter) => caracter.compareTo('0') >= 0 && caracter.compareTo('9') <= 0;
  // Verifica si el carácter es uno de los símbolos aceptados por el lenguaje
  bool esSimbolo(String caracter) => '*(),=<>;'.contains(caracter) || caracter == '!';
  // Lee una palabra compuesta de letras o dígitos (equivale a <palabra>)
  String leerPalabra() {
    String palabra = '';
    while (posicion < entrada.length && (esLetra(entrada[posicion]) || esDigito(entrada[posicion]))) {
      palabra += entrada[posicion];
      posicion++;
    }
    // Convierte a mayúscula para facilitar la comparación
    return palabra.toUpperCase();
  }
  // Lee números con o sin porcentaje (para PRIMEROS <num>% y ULTIMOS <num>%)
  String leerNumeroOPorcentaje() {
    String numero = '';
    while (posicion < entrada.length && esDigito(entrada[posicion])) {
      numero += entrada[posicion];
      posicion++;
    }
    if (posicion < entrada.length && entrada[posicion] == '%') {
      numero += '%';
      posicion++;
    }
    return numero;
  }
  // Lee una cadena encerrada entre comillas dobles (equivale a <cad>)
  String leerCadena() {
    String resultado = '"';
    posicion++;
    while (posicion < entrada.length && entrada[posicion] != '"') {
      resultado += entrada[posicion];
      posicion++;
    }
    if (posicion < entrada.length) {
      resultado += '"';
      posicion++;
    }
    return resultado;
  }
  // Lee símbolos de comparación simples o dobles (como ¡=, <=, >=, etc)
  String leerSimbolo() {
    String simbolo = entrada[posicion];
    posicion++;
    if (posicion < entrada.length) {
      String siguiente = entrada[posicion];
      if ((simbolo == '!' || simbolo == '<' || simbolo == '>') &&
          (siguiente == '=' || siguiente == '>' || siguiente == '<')) {
        simbolo += siguiente;
        posicion++;
      }
    }
    return simbolo;
  }
}
// Esta clase representa el análisis sintáctico: revisa si los tokens forman una estructura válida
class AnalizadorSintactico {
  List<String> tokens; // Verifica si el carácter es uno de los símbolos aceptados por el lenguaje
  int posicion = 0;

  AnalizadorSintactico(this.tokens);
  // Este método inicia el análisis de la consulta <select>
  bool analizar() {
    if (!esperar("SELECCIONA")) return false;
    // Verifica si viene la parte [TODOS | PRIMEROS <num>% | ULTIMOS <num>%]
    if (es("TODOS")) {
      posicion++;
    } else if (es("PRIMEROS") || es("ULTIMOS")) {
      posicion++;
      if (!esNumeroPorcentaje(tokens[posicion])) return false;
      posicion++;
    } else {
      return false;
    }
    // Luego de la palabra clave viene el listado de columnas o *
    if (es("*")) {
      posicion++;
    } else {
      if (!listaValores()) return false;
    }
    // Verifica la palabra clave DE y las tablas que siguen
    if (!esperar("DE")) return false;
    if (!listaCadenas()) return false;
    // Si aparece DONDE, se espera una condición
    if (es("DONDE")) {
      posicion++;
      if (!condicion()) return false;
    }
    // Si aparece ORDENADO POR, se procesa el orden
    if (es("ORDENADO")) {
      posicion++;
      if (!esperar("POR")) return false;
      if (!valor()) return false;
      if (es("ASC") || es("DESC")) posicion++;
    }
    // Se espera un punto y coma para cerrar la consulta
    if (posicion < tokens.length && tokens[posicion] == ";") {
      posicion++;
    } else {
      return false;
    }
    return posicion == tokens.length;
  }
  // Esta función verifica condiciones anidadas (corresponde a <condicion>)
  bool condicion() {
    // Si la condición comienza con NO, se avanza y se vuelve a evaluar como subcondición
    if (es("NO")) {
      posicion++;
      return condicion();
    }
    // Si hay un paréntesis de apertura, se asume que es una condición agrupada
    if (es("(")) {
      posicion++;
      if (!condicion()) return false; // Se analiza la condición interna recursivamente
      if (!esperar(")")) return false; // Se espera el paréntesis de cierre
      // Si no es negada ni agrupada, se espera que sea una condición simple
    } else if (!condicionSimple()) {
      return false;
    }
    // Después de una condición válida, se puede encadenar con Y o O
    while (es("Y") || es("O")) {
      posicion++;
      if (!condicion()) return false; // Se analiza recursivamente la siguiente condicion
    }
    // Si pasa todas las validaciones, la condición completa es válida
    return true;
  }
  // Verifica condiciones simples (como <val> <op> <val>, <val> ES NULO, etc)
  bool condicionSimple() {
    if (valorSimple()) {
      // Si la condición contiene NO, se consume
      if (es("NO")) {
        posicion++;
      }
      // Caso 1: <valor> [NO] ES NULO
      if (es("ES")) {
        posicion++;
        if (es("NULO")) {
          posicion++;
          return true;
        }
        return false;
      }

      if (esComparador()) {
        posicion++;
        return valorSimple();
      }
    // Caso 2: <valor> [NO] EMPIEZA CON <valor>
      if (es("NO")) {
        posicion++;
        if (es("EMPIEZA")) {
          posicion++;
          if (!esperar("CON")) return false;
          return valorSimple();
          // Caso 3: <valor> [NO] CONTIENE <valor>
        } else if (es("CONTIENE")) {
          posicion++;
          return valorSimple();
          // Caso 4 y 5: <valor> [NO] ESTA ENTRE <val> Y <val> o ESTA DENTRO DE (<val> {, <val>}*)
        } else if (es("ESTA")) {
          posicion++;
          if (es("ENTRE")) {
            posicion++;
            if (!valorSimple()) return false;
            if (!esperar("Y")) return false;
            return valorSimple();
          } else if (es("DENTRO")) {
            posicion++;
            if (!esperar("DE")) return false;
            if (!esperar("(")) return false;
            if (!listaValores()) return false;
            return esperar(")");
          }
        }
      }
      // Manejo de variantes sin “NO”
      if (es("EMPIEZA")) {
        posicion++;
        if (!esperar("CON")) return false;
        return valorSimple();
      }

      if (es("CONTIENE")) {
        posicion++;
        return valorSimple();
      }

      if (es("ESTA")) {
        posicion++;
        if (es("ENTRE")) {
          posicion++;
          if (!valorSimple()) return false;
          if (!esperar("Y")) return false;
          return valorSimple();
        } else if (es("DENTRO")) {
          posicion++;
          if (!esperar("DE")) return false;
          if (!esperar("(")) return false;
          if (!listaValores()) return false;
          return esperar(")");
        }
      }

      return true;
    }
    return false;
  }
  // Maneja una lista de valores separados por comas (<val>{, <val>}*)
  bool listaValores() {
    if (!valor()) return false;
    while (es(",")) {
      posicion++;
      if (!valor()) return false;
    }
    return true;
  }
  // Maneja una lista de cadenas (<cad>{, <cad>}*)
  bool listaCadenas() {
    if (!cadena()) return false;
    while (es(",")) {
      posicion++;
      if (!cadena()) return false;
    }
    return true;
  }
// Verifica si un token es un valor válido (<val> ::= <num> | <cad>)
  bool valor() => numero() || cadena();
  bool valorSimple() => valor();
  // Verifica si un token es un número
  bool numero() {
    if (posicion < tokens.length && esNumero(tokens[posicion])) {
      posicion++;
      return true;
    }
    return false;
  }
  // Verifica si es una cadena (con comillas o palabra)
  bool cadena() {
    if (posicion < tokens.length &&
        (tokens[posicion].startsWith('"') && tokens[posicion].endsWith('"') ||
            esPalabra(tokens[posicion]))) {
      posicion++;
      return true;
    }
    return false;
  }
  // Verifica que el token contenga solo dígitos
  bool esNumero(String token) {
    for (var caracter in token.runes) {
      if (caracter < 48 || caracter > 57) return false;
    }
    return true;
  }
  // Verifica si el token cumple con la regla <palabra>
  bool esPalabra(String token) {
    if (token.isEmpty || !esLetra(token[0])) return false;
    for (var caracter in token.runes) {
      final ch = String.fromCharCode(caracter);
      if (!esLetra(ch) && !esDigito(ch)) return false;
    }
    return true;
  }
  // Verifica si el token es un numero o un numero con %
  bool esNumeroPorcentaje(String token) {
    if (token.endsWith('%')) {
      return esNumero(token.substring(0, token.length - 1));
    }
    return esNumero(token);
  }

  bool esLetra(String caracter) =>
      caracter.toLowerCase().compareTo('a') >= 0 && caracter.toLowerCase().compareTo('z') <= 0;

  bool esDigito(String caracter) => caracter.compareTo('0') >= 0 && caracter.compareTo('9') <= 0;
  // Lista de operadores válidos (<op>)
  bool esComparador() {
    const comparadores = ['<', '<=', '!<', '>', '>=', '!>', '=', '!=', '<>'];
    return posicion < tokens.length && comparadores.contains(tokens[posicion]);
  }
  // Avanza si el token actual es el esperado
  bool esperar(String esperado) {
    if (posicion < tokens.length && tokens[posicion] == esperado) {
      posicion++;
      return true;
    }
    return false;
  }
  // Solo compara si el token actual es igual al esperado
  bool es(String esperado) {
    return posicion < tokens.length && tokens[posicion] == esperado;
  }
}
// Función principal: punto de entrada del programa
void main() {
  final rutaArchivo = 'consulta.sql';
  final archivo = File(rutaArchivo);
  // Verifica que el archivo exista y no esté vacío
  if (!archivo.existsSync()) {
    print('El archivo "$rutaArchivo" no existe.');
    return;
  }

  final contenido = archivo.readAsStringSync();
  if (contenido.isEmpty) {
    print('El archivo está vacío.');
    return;
  }
  // Ejecuta el análisis léxico y luego el sintáctico
  final lexico = AnalizadorLexico(contenido);
  final listaTokens = lexico.obtenerTokens();
  final analizador = AnalizadorSintactico(listaTokens);
  // Informa si la sintaxis es válida o hay errores
  if (analizador.analizar()) {
    print('\n\x1B[32mSINTAXIS OK.\x1B[0m\n');
  } else {
    print('\n\x1B[31mERROR DE SINTAXIS.\x1B[0m\n');
  }
}