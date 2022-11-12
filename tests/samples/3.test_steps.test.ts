import { assertEquals } from "https://deno.land/std@0.163.0/testing/asserts.ts";
import { Client } from "https://deno.land/x/postgres@v0.15.0/mod.ts";

interface User {
  id: number;
  name: string;
}

interface Book {
  id: number;
  title: string;
}

Deno.test("database", async (t) => {
  const client = new Client({
    user: "user",
    database: "test",
    hostname: "localhost",
    port: 5432,
  });
  await client.connect();

  // provide a step name and function
  await t.step("insert user", async () => {
    const users = await client.queryObject<User>(
      "INSERT INTO users (name) VALUES ('Deno') RETURNING *",
    );
    assertEquals(users.rows.length, 1);
    assertEquals(users.rows[0].name, "Deno");
  });

  // or provide a test definition
  await t.step({
    name: "insert book",
    fn: async () => {
      const books = await client.queryObject<Book>(
        "INSERT INTO books (name) VALUES ('The Deno Manual') RETURNING *",
      );
      assertEquals(books.rows.length, 1);
      assertEquals(books.rows[0].title, "The Deno Manual");
    },
    ignore: false,
    // these default to the parent test or step's value
    sanitizeOps: true,
    sanitizeResources: true,
    sanitizeExit: true,
  });

  // nested steps are also supported
  await t.step("update and delete", async (t) => {
    await t.step("update", () => {
      // even though this test throws, the outer promise does not reject
      // and the next test step will run
      throw new Error("Fail.");
    });

    await t.step("delete", () => {
      // ...etc...
    });
  });

  // steps return a value saying if they ran or not
  const testRan = await t.step({
    name: "copy books",
    fn: () => {
      // ...etc...
    },
    ignore: true, // was ignored, so will return `false`
  });

  // steps can be run concurrently if sanitizers are disabled on sibling steps
  const testCases = [1, 2, 3];
  await Promise.all(testCases.map((testCase) =>
    t.step({
      name: `case ${testCase}`,
      fn: async () => {
        // ...etc...
      },
      sanitizeOps: false,
      sanitizeResources: false,
      sanitizeExit: false,
    })
  ));

  client.end();
});
