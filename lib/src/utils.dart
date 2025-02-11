String toCamelCase(String input) => input.replaceAllMapped(
  RegExp(r'_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
);

String toPascalCase(String input) => input.replaceAllMapped(
  RegExp(r'(?:^|_)([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
);

String toSnakeCase(String input) => input.replaceAllMapped(
  RegExp(r'([A-Z])'),
      (match) => '_${match.group(0)!.toLowerCase()}',
).replaceFirst(RegExp(r'^_'), '');