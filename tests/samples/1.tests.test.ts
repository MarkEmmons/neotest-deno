import { assertEquals } from "https://deno.land/std@0.163.0/testing/asserts.ts";

// Compact form: name and function
Deno.test("hello world #1", () => {
  const x = 1 + 2;
  assertEquals(x, 3);
});

// Compact form: named function.
Deno.test(function helloWorld3() {
  const x = 1 + 2;
  assertEquals(x, 3);
});

// Longer form: test definition.
Deno.test({
  name: "hello world #2",
  fn: () => {
    const x = 1 + 2;
    assertEquals(x, 3);
  },
});

// Similar to compact form, with additional configuration as a second argument.
Deno.test("hello world #4", { permissions: { read: true } }, () => {
  const x = 1 + 2;
  assertEquals(x, 3);
});

// Similar to longer form, with test function as a second argument.
Deno.test(
  { name: "hello world #5", permissions: { read: true } },
  () => {
    const x = 1 + 2;
    assertEquals(x, 3);
  },
);

// Similar to longer form, with a named test function as a second argument.
Deno.test({ permissions: { read: true } }, function helloWorld6() {
  const x = 1 + 2;
  assertEquals(x, 3);
});
