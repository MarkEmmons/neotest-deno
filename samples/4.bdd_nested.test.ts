// https://deno.land/std@0.163.0/testing/bdd_examples/user_nested_test.ts
import {
  assertEquals,
  assertStrictEquals,
  assertThrows,
} from "https://deno.land/std@0.163.0/testing/asserts.ts";
import {
  afterEach,
  beforeEach,
  describe,
  it,
} from "https://deno.land/std@0.163.0/testing/bdd.ts";
import { User } from "https://deno.land/std@0.163.0/testing/bdd_examples/user.ts";

describe("User", () => {
  it("users initially empty", () => {
    assertEquals(User.users.size, 0);
  });

  it("constructor", () => {
    try {
      const user = new User("Kyle");
      assertEquals(user.name, "Kyle");
      assertStrictEquals(User.users.get("Kyle"), user);
    } finally {
      User.users.clear();
    }
  });

  describe("age", () => {
    let user: User;

    beforeEach(() => {
      user = new User("Kyle");
    });

    afterEach(() => {
      User.users.clear();
    });

    it("getAge", function () {
      assertThrows(() => user.getAge(), Error, "Age unknown");
      user.age = 18;
      assertEquals(user.getAge(), 18);
    });

    it("setAge", function () {
      user.setAge(18);
      assertEquals(user.getAge(), 18);
    });
  });
});
