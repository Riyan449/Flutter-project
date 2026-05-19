void main() {
  final regex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$");
  
  final testEmails = [
    "test@test.com",
    "abc@def.com",
    "random",
    "random@email",
    "invalid@",
    "123@123.123"
  ];

  for (final email in testEmails) {
    print("$email: ${regex.hasMatch(email)}");
  }
}
