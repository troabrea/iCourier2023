---
version: 1
slug: "lib-asistente-asistente-dart"
primary_target: "lib/asistente/asistente.dart"
related_targets: ["lib/services/assistant_service.dart","lib/asistente/assistant_shortcuts.dart"]
---

## Scope and mode

The conversational assistant surface: the screen at `/asistente`, its entry
points and the webhook transport behind them. Visitor mode: Operate.

The assistant occupies the header position that used to open the branch
WhatsApp, on every screen that carried one — the five tab roots plus services —
and on the home brand header. A customer with no session still gets WhatsApp
there, because the webhook cannot answer without one. Two further entries exist:
a row in "Más" and a hand-off row at the end of the FAQ list.

The assistant's own header carries no contact action. Its right-hand position
belongs to a reset that appears only once there is a conversation to clear, and
clearing asks first because the turns are not stored anywhere. A person is
offered inside the answer that needs one, never as standing chrome.

## Audience, job, action

A signed-in courier customer on a phone, usually one-handed, who has a question
the app's fixed screens answer indirectly at best: "do I have anything ready",
"what time does my branch close", "what would five pounds cost". The job is to
get the answer in plain Spanish and, when the answer points at a screen, to land
on it in one tap.

## Proof and content

Answers come from the hosted n8n workflow at
`https://n8n.barolitcloud.dev/webhook/courier/assistant`, which resolves the
customer's own branch, service, FAQ, and package data from the `sessionId` the
request already carries. Nothing on this surface is authored copy pretending to
be an answer.

## Constraints

- Signed-in only; the request is meaningless without a session.
- No streaming and no client-side thread id: one POST, one markdown answer,
  measured between three and twenty-two seconds.
- The conversation is never written to disk. It ends with the screen.
- The assistant advises and points; it never acts for the customer.
- Replies are always Spanish; the screen chrome is translated es/en.
- Thirty-five brands render this surface, so every colour, corner and face
  comes from `BrandTokens`.

## Direction and memorable moment

Answer-as-document (candidate 7 of 7, seed key 7114e227). The answer owns the
full brand width at reading scale instead of a chat bubble, because the real
answers are branch directories and service lists that a 70%-width bubble
destroys. Earlier exchanges compress into a one-line ribbon of questions above
the document. The memorable moment is the first branch answer: a full-width,
selectable, properly typeset list where a chat app would have shown a wall of
folded lines.

## Conversation lifetime

The turns live in `AssistantConversation`, a singleton that outlives the screen,
so following a shortcut into a tab and coming back resumes the conversation.
Nothing is written to disk: it ends with the process, with a logout or expiry
event, when a different account adopts the store, or when the customer clears it
from the header.

## Handoff to a person

The workflow answers `{"output", "needs_human", "summary"}`. When it flags an
exchange and supplies a summary, a card under the answer opens the branch's
WhatsApp with that summary already typed; the customer still presses send. The
summary is written in the customer's own first person so it can be sent as-is.
A handoff card takes the primary treatment and demotes every screen shortcut to
an outline, because when the answer needs a person no screen in the app is the
answer. The contract, the JSON schema and the workflow's system prompt live in
`docs/asistente-n8n.md`.

## Unresolved

- No way to cancel a question in flight; the customer's only exit from a long
  wait is the back button.
- A shortcut into a tab closes the screen, because pushing a tab root stacks the
  navigation shell on itself. The conversation survives, but the customer has to
  reopen the assistant to see it.
- Shortcut detection is a local keyword table. It will miss intents the
  workflow phrases in words the table does not carry. Live packages and the
  date-range history are told apart by decisive past-time words, checked against
  answers captured from the live workflow; a phrasing neither list anticipates
  falls back to the current reception list.
- The workflow ignores locale, so an English-language customer still gets a
  Spanish answer inside a translated screen.
