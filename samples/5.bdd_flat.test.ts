// https://deno.land/std@0.163.0/testing/bdd_examples/user_flat_test.ts
import {
  assertEquals,
  assertStrictEquals,
  assertThrows,
} from "https://deno.land/std@0.163.0/testing/asserts.ts";
import {
  describe,
  it,
} from "https://deno.land/std@0.163.0/testing/bdd.ts";
import { User } from "https://deno.land/std@0.163.0/testing/bdd_examples/user.ts";

const userTests = describe("User");

it(userTests, "users initially empty", () => {
  assertEquals(User.users.size, 0);
});

it(userTests, "constructor", () => {
  try {
    const user = new User("Kyle");
    assertEquals(user.name, "Kyle");
    assertStrictEquals(User.users.get("Kyle"), user);
  } finally {
    User.users.clear();
  }
});

const ageTests = describe({
  name: "age",
  suite: userTests,
  beforeEach(this: { user: User }) {
    this.user = new User("Kyle");
  },
  afterEach() {
    User.users.clear();
  },
});

it(ageTests, "getAge", function () {
  const { user } = this;
  assertThrows(() => user.getAge(), Error, "Age unknown");
  user.age = 18;
  assertEquals(user.getAge(), 18);
});

it(ageTests, "setAge", function () {
  const { user } = this;
  user.setAge(18);
  assertEquals(user.getAge(), 18);
});
