import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Protege o arquivo completo do backup antes de ele sair do armazenamento local.
///
/// O formato guarda apenas os parâmetros públicos da criptografia (versão,
/// salt, nonce e dados cifrados). A senha nunca é gravada no aparelho nem no
/// arquivo; ela é usada para derivar uma chave com Argon2id e AES-GCM autentica
/// o conteúdo para que alterações ou senhas incorretas sejam detectadas.
class CriptografiaBackup {
  CriptografiaBackup._();

  static const String _identificador = 'OGYMBKP1';
  static const int _tamanhoSalt = 16;
  static const int _tamanhoNonce = 12;
  static const int _tamanhoAutenticacao = 16;

  // OWASP recomenda Argon2id com ao menos 19 MiB, paralelismo 1 e 2 passagens.
  // O formato versionado permite trocar os parâmetros sem quebrar backups velhos.
  static final Argon2id _derivacao = Argon2id(
    memory: 19 * 1024,
    parallelism: 1,
    iterations: 2,
    hashLength: 32,
  );
  static final AesGcm _cifra = AesGcm.with256bits();

  /// Criptografa os bytes do ZIP; uma nova sequência aleatória é usada por cópia.
  static Future<Uint8List> criptografar(Uint8List dados, String senha) async {
    if (senha.trim().length < 8) {
      throw const FormatException(
        'Use uma senha com pelo menos 8 caracteres para proteger o backup.',
      );
    }

    final aleatorio = Random.secure();
    final salt = List<int>.generate(
      _tamanhoSalt,
      (_) => aleatorio.nextInt(256),
      growable: false,
    );
    final chave = await _derivacao.deriveKeyFromPassword(
      password: senha,
      nonce: salt,
    );
    final caixa = await _cifra.encrypt(
      dados,
      secretKey: chave,
      nonce: _cifra.newNonce(),
    );

    return Uint8List.fromList(<int>[
      ..._identificador.codeUnits,
      ...salt,
      ...caixa.concatenation(),
    ]);
  }

  /// Descriptografa somente arquivos com cabeçalho reconhecido e autenticação válida.
  static Future<Uint8List> descriptografar(
    Uint8List arquivo,
    String senha,
  ) async {
    final prefixo = _identificador.codeUnits;
    final tamanhoCabecalho = prefixo.length + _tamanhoSalt;
    final tamanhoMinimo =
        tamanhoCabecalho + _tamanhoNonce + _tamanhoAutenticacao;
    if (arquivo.length < tamanhoMinimo || !_temPrefixo(arquivo, prefixo)) {
      throw const FormatException(
        'O arquivo não é um backup criptografado válido.',
      );
    }
    if (senha.isEmpty) {
      throw const FormatException(
        'Informe a senha usada ao exportar o backup.',
      );
    }

    final salt = arquivo.sublist(prefixo.length, tamanhoCabecalho);
    final chave = await _derivacao.deriveKeyFromPassword(
      password: senha,
      nonce: salt,
    );
    final caixa = SecretBox.fromConcatenation(
      arquivo.sublist(tamanhoCabecalho),
      nonceLength: _tamanhoNonce,
      macLength: _tamanhoAutenticacao,
      copy: false,
    );

    try {
      final dados = await _cifra.decrypt(caixa, secretKey: chave);
      return Uint8List.fromList(dados);
    } on SecretBoxAuthenticationError {
      throw const FormatException(
        'Senha incorreta ou arquivo de backup alterado/corrompido.',
      );
    }
  }

  static bool _temPrefixo(Uint8List bytes, List<int> prefixo) {
    for (var i = 0; i < prefixo.length; i++) {
      if (bytes[i] != prefixo[i]) return false;
    }
    return true;
  }

  static bool ehBackupCriptografado(Uint8List arquivo) {
    final prefixo = _identificador.codeUnits;
    return arquivo.length >= prefixo.length && _temPrefixo(arquivo, prefixo);
  }
}
