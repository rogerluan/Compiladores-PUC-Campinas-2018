//
//  virtual_machine_v2Tests.swift
//  virtual-machine-v2Tests
//
//  Created by Roger Oba on 08/08/18.
//  Copyright © 2018 Roger Oba. All rights reserved.
//

import XCTest
@testable import virtual_machine_v2

class virtual_machine_v2Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        let test1 =
"""
programa teste; {*Teste OK*}
var x,a,b,c,z:inteiro;
inicio
 x:=1;
 a:=2;
 b:=3;
 c:=7;
 z:=1;
 se (x+a*b)>=((b+c)div z)
 entao escreva(x)
 senao escreva(a)
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test1), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertNoThrow(try syntacticAnalyzer.analyzeProgram())
            print(NSLocalizedString("✅ Lexical, Syntactic and Semantic Analysis Completed with No Errors", comment: ""))
        } else {
            XCTFail()
        }

        let test3 =
"""
programa teste; {ERRO inteiros com e logico}
var x,a,b,c,z:inteiro;
inicio
 x:=1;
 a:=2;
 b:=3;
 c:=7;
 z:=1;
 se (x+a*b)e((b+c)div z)  {ERRO inteiros com e}
 entao escreva(x)
 senao escreva(a)
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test3), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "operacao entre AND e inteiros") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test4 =
"""
programa teste; {ERRO - express„o nao booleana}
var x,a,b,c,z:inteiro;

inicio
 x:=1;
 a:=2;
 b:=3;
 c:=7;
 z:=1;
 se (x+a*b)          {ERRO - express„o nao booleana}
 entao escreva(x)
 senao escreva(a)
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test4), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "expressão nao booleana") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test5 =
"""
programa teste; {ERRO - variavel nao booleana, aka esperava que o z fosse inteiro }
var x,a,b,c:inteiro;
    z: booleano;
inicio
 x:=1;
 a:=2;
 b:=3;
 c:=7;
 se (x+a*b)<=((b+c)div z) {ERRO - variavel nao booleana, aka esperava que o z fosse inteiro }
 entao escreva(x)
 senao escreva(a)
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test5), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "esperava que o z fosse inteiro ") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test6 =
"""
programa teste; {ERRO atribuindo inteiros a booleano}
var x,a,b,c,z:booleano;
inicio
 x:=1;           {ERRO atribuindo inteiros a booleano}
 a:=2;
 b:=3;
 c:=7;
 z:=1;
 se (x+a*b)ou((b+c)div z)  {ERRO inteiros e ou}
 entao escreva(x)
 senao escreva(a)
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test6), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "atribuindo inteiros a booleano") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test7 =
"""
programa teste; {ERRO express„o nao booleanoa}
var x,a,b,c,z:inteiro;

inicio
x:=1;
a:=2;
b:=3;
c:=7;
z:=1;
enquanto (x)          {ERRO express„o nao booleanoa}
faca inicio
escreva(x)
fim
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test7), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "expressao nao booleana") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test8 =
"""
programa testefinal; {ERRO - variavel duplicada}

var opcao,x,y:inteiro;


procedimento numeros;
var x,y,total: inteiro;

procedimento dobro;
var media: inteiro;
inicio
  media:=(x+y)*2;
  escreva(media)
fim;
inicio
  leia(x);
  leia(y);
  total:= x+y;
  escreva(total);  {soma dos numeros lidos}
  dobro            {Calcula a media aritmetica dos numeros lidos}
fim;

procedimento p;               {calcula fatorial de um numero lido}
var z: inteiro;
    z:booleano;            {ERRO - variavel duplicada}
inicio
  z:= x; x:=x-1;
  se  z>1 entao p  {recursivo}
  senao  y:=1;
  y:=y*z
fim { p };

inicio
  leia(opcao);
  se opcao = 1
  entao numeros
  senao inicio
         leia(x);
         p;
         escreva(y)
       fim
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test8), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "variável duplicada") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test9 =
"""
programa testefinal; {ERRO variavel nao declarada}

var opcao,x,y:inteiro;


procedimento numeros;
var x,y: inteiro;

procedimento dobro;
var media: inteiro;
inicio
  media:=(x+y)*2;
  escreva(media)
fim;

inicio
  leia(x);
  leia(y);
  total:= x+y;         {ERRO variavel nao declarada}
  escreva(total);  {soma dos numeros lidos}
  dobro            {Calcula a media aritmetica dos numeros lidos}
fim;

procedimento p;               {calcula fatouial de um numero lido}
var total,z: inteiro;
inicio
  z:= x; x:=x-1;
  se  z>1 entao p  {recursivo}
  senao  y:=1;
  y:=y*z
fim { p };

inicio
  leia(opcao);
  se opcao = 1
  entao numeros
  senao inicio
         leia(x);
         p;
         escreva(y)
       fim
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test9), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "variável nao declarada") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test10 =
"""
programa testefinal; {ERRO incompatibilidade de tipos }

var opcao,x,y:inteiro;


procedimento numeros;
var x,y,total: inteiro;

procedimento media;
var edia: inteiro;       {ERRO incompatibilidade de tipos}
inicio
  edia:= verdadeiro;
  escreva(edia)
fim;

inicio
  leia(x);
  leia(y);
  total:= x+y;
  escreva(total);  {soma dos numeros lidos}
  media            {Calcula a media aritmetica dos numeros lidos}
fim;

procedimento p;               {calcula fatouial de um numero lido}
var z: inteiro;
inicio
  z:= x; x:=x-1;
  se  z>1 entao p  {recursivo}
  senao  y:=1;
  y:=y*z
fim { p };

inicio
  leia(opcao);
  se opcao = 1
  entao numeros
  senao inicio
         leia(x);
         p;
         escreva(y)
       fim
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test10), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "incompatibilidade de tipos") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test11 =
"""
programa testefinal; {ERRO procedimento duplicado}

var opcao,x,y:inteiro;


procedimento numeros;
var x,y,total: inteiro;

procedimento numeros;         {ERRO procedimento duplicado}
var media: inteiro;
inicio
  media:=(x+y)div 2;
  escreva(media)
fim;

inicio
  leia(x);
  leia(y);
  total:= x+y;
  escreva(total);  {soma dos numeros lidos}
  media            {Calcula a media aritmetica dos numeros lidos}
fim;

procedimento p;               {calcula fatouial de um numero lido}
var z: inteiro;
inicio
  z:= x; x:=x-1;
  se  z>1 entao p  {recursivo}
  senao  y:=1;
  y:=y*z
fim { p };

inicio
  leia(opcao);
  se opcao = 1
  entao numeros
  senao inicio
         leia(x);
         p;
         escreva(y)
       fim
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test11), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "procedimento duplicado") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test12 =
"""
programa testefinal; {ERRO procedimento duplicado}

var opcao,x,y:inteiro;


procedimento numeros;
var x,y,total: inteiro;

procedimento numero;
var media: inteiro;
inicio
  media:=(x+y)div 2;
  escreva(media)
fim;

inicio
  leia(x);
  leia(y);
  total:= x+y;
  escreva(total);  {soma dos numeros lidos}
  numero            {Calcula a media aritmetica dos numeros lidos}
fim;

procedimento numeros;            {ERRO procedimento duplicado}
    {calcula fatouial de um numero lido}
var z: inteiro;
inicio
  z:= x; x:=x-1;
  se  z>1 entao p  {recursivo}
  senao  y:=1;
  y:=y*z
fim { p };

inicio
  leia(opcao);
  se opcao = 1
  entao numeros
  senao inicio
         leia(x);
         p;
         escreva(y)
       fim
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test12), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "procedimento duplicado") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test13 =
"""
programa testefinal;          {ERRO - variavel duplicada}

var opcao,x,y:inteiro;


procedimento numeros;
var x,y,total: inteiro;
    x:inteiro;                          {ERRO - variavel duplicada}

procedimento dobro;
var media: inteiro;
inicio
  media:=(x+y)*2;
  escreva(media)
fim;
inicio
  leia(x);
  leia(y);
  total:= x+y;
  escreva(total);  {soma dos numeros lidos}
  dobro            {Calcula a media aritmetica dos numeros lidos}
fim;

procedimento p;               {calcula fatorial de um numero lido}
var z: inteiro;
    x:booleano;
inicio
  z:= x; x:=x-1;
  se  z>1 entao p  {recursivo}
  senao  y:=1;
  y:=y*z
fim { p };

inicio
  leia(opcao);
  se opcao = 1
  entao numeros
  senao inicio
         leia(x);
         p;
         escreva(y)
       fim
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test13), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "variavel duplicada") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test14 =
"""
programa testefinal; {ERRO  - variavel nao declarada}

var opcao,x,y:inteiro;


procedimento numeros;
var x,y: inteiro;

procedimento dobro;
var media,total: inteiro;
inicio
  media:=(x+y)*2;
  escreva(media)
fim;

inicio
  leia(x);
  leia(y);
  total:= x+y;
  escreva(total);   {ERRO  - variavel nao declarada}
  dobro            {Calcula a media aritmetica dos numeros lidos}
fim;

procedimento p;               {calcula fatorial de um numero lido}
var z1: inteiro;
inicio
  z:= x; x:=x-1;
  se  z>1 entao p  {recursivo}
  senao  y:=1;
  y:=y*z
fim { p };

inicio
  leia(opcao);
  se opcao = 1
  entao numeros
  senao inicio
         leia(x);
         p;
         escreva(y)
       fim
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test14), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertThrowsError(try syntacticAnalyzer.analyzeProgram(), "variavel nao declarada") { error in
                print(error)
            }
        } else {
            XCTFail()
        }

        let test15 =
"""
programa test;

var a,b: inteiro;


funcao soma: inteiro;
var c,a: inteiro;

  procedimento ler;
  inicio
     leia (c);
     leia (a);
     escreva (soma);
fim;

  procedimento loop;
  var x: inteiro;
  inicio
    leia (x);   {para parar digite um valor maior que 9 }
    se x < 10
    entao ler;
  fim;

 inicio
  loop;
  soma:= c+a;
 fim;

inicio
  escreva(soma)
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test15), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertNoThrow(try syntacticAnalyzer.analyzeProgram())
            print(NSLocalizedString("✅ Lexical, Syntactic and Semantic Analysis Completed with No Errors", comment: ""))
        } else {
            XCTFail()
        }

        let test16 =
"""
programa testefinal;  {* Calcula a media ou fatorial - OK *}

var opcao,x,y:inteiro;


procedimento numeros;
var x,y,total: inteiro;

procedimento media;
var edia: inteiro;
inicio
  edia:=(x+y)div 2;
  se x>y entao escreva(x) senao escreva(y);
  escreva(edia)
fim;

inicio
  leia(x);
  leia(y);
  total:= x+y;
  escreva(total);  {soma dos numeros lidos}
  media            {Calcula a media aritmetica dos numeros lidos}
fim;

procedimento p;               {calcula fatouial de um numero lido}
var z: inteiro;
inicio
  z:= x; x:=x-1;
  se  z>1 entao p  {recursivo}
  senao  y:=1;
  y:=y*z
fim { p };

inicio
  leia(opcao);
  se opcao = 1
  entao numeros
  senao inicio
         leia(x);
         p;
         escreva(y)
       fim
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test16), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertNoThrow(try syntacticAnalyzer.analyzeProgram())
            print(NSLocalizedString("✅ Lexical, Syntactic and Semantic Analysis Completed with No Errors", comment: ""))
        } else {
            XCTFail()
        }

        let test17 =
"""
programa testefinal;  {calcula o dobro ou fatorial - OK}

var opcao,x,y:inteiro;


procedimento numeros;
var x,y,total: inteiro;

procedimento dobro;
var media: inteiro;
inicio
  media:=(x+y)*2;
  escreva(media)
fim;

inicio
  leia(x);
  leia(y);
  total:= x+y;
  escreva(total);  {soma dos numeros lidos}
  dobro            {Calcula o dobro dos numeros lidos}
fim;

procedimento p;               {calcula fatorial de um numero lido}
var z: inteiro;
inicio
  z:= x; x:=x-1;
  se  z>1 entao p  {recursivo}
  senao  y:=1;
  y:=y*z
fim { p };

inicio
  leia(opcao);
  se opcao = 1
  entao numeros
  senao inicio
         leia(x);
         p;
         escreva(y)
       fim
fim.
"""
        if let lexicalAnalyzer = LexicalAnalyzer(sourceCode: test17), let syntacticAnalyzer = SyntacticAnalyzer(lexicalAnalyzer: lexicalAnalyzer) {
            XCTAssertNoThrow(try syntacticAnalyzer.analyzeProgram())
            print(NSLocalizedString("✅ Lexical, Syntactic and Semantic Analysis Completed with No Errors", comment: ""))
        } else {
            XCTFail()
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
