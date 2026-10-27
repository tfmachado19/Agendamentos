# Agendamentos de Aulas Particulares — Esboço

Sistema para organizar as aulas particulares do dia: quais alunos têm aula,
com qual professor e em qual sala, garantindo que **nem o professor nem a sala
fiquem com dois horários ao mesmo tempo**.

## 1. Problema

- Vários professores, várias salas, muitos alunos.
- Cada aula precisa de **3 coisas livres ao mesmo tempo**: aluno, professor e sala.
- Precisamos enxergar o dia inteiro de forma rápida (quem, com quem, onde, quando).

## 2. Entidades (modelo de dados)

| Entidade      | Campos principais                                                      |
|---------------|------------------------------------------------------------------------|
| **Professor** | id, nome, disciplinas, telefone, disponibilidade (dias/horários)       |
| **Sala**      | id, nome, capacidade, recursos (quadro, TV, piano…)                    |
| **Aluno**     | id, nome, responsável, telefone, observações                           |
| **Aula**      | id, data, hora início, hora fim, aluno, professor, sala, disciplina, status (agendada / realizada / cancelada / falta) |

```
Professor 1 ──< Aula >── 1 Aluno
                 │
                 1
               Sala
```

## 3. Regras de negócio

1. **Sem conflito de professor**: um professor não pode ter duas aulas com horários sobrepostos.
2. **Sem conflito de sala**: uma sala não pode ter duas aulas com horários sobrepostos.
3. **Sem conflito de aluno**: um aluno não pode estar em duas aulas ao mesmo tempo.
4. Dois horários se sobrepõem quando `inicioA < fimB` **e** `inicioB < fimA`
   (uma aula que termina 10:00 e outra que começa 10:00 **não** conflitam).
5. **Duração mínima de 1h** por aula (opções: 1h, 1h30, 2h, 2h30, 3h).
6. Aulas canceladas liberam professor e sala.
7. Ao escolher data/horário, o sistema **sugere só as salas e professores livres**.
8. (Futuro) Respeitar a disponibilidade cadastrada do professor e recursos da sala.

## 4. Telas

1. **Agenda do dia** — grade com horários nas linhas e salas nas colunas
   (alternável para ver por professor). Cada bloco mostra aluno + professor.
2. **Novo agendamento** — data, horário, duração, aluno, professor, sala;
   avisa conflitos antes de salvar.
3. **Lista do dia** — lista em ordem de horário (boa para imprimir / recepção).
4. **Cadastros** — professores, salas e alunos.

## 5. Protótipo

O arquivo [`index.html`](index.html) é um protótipo funcional, sem instalação:
basta abrir no navegador. Os dados ficam salvos no próprio navegador
(localStorage) e vêm alguns exemplos pré-carregados.

Já implementado no protótipo:
- Agenda do dia por **sala** ou por **professor**
- Cadastro de aulas com verificação de conflito (professor, sala e aluno)
- Lista de salas livres no horário escolhido
- Lista do dia e cancelamento de aulas
- Cadastro simples de professores, salas e alunos

## 6. Próximos passos (roadmap)

| Fase | O que entra |
|------|-------------|
| 1. MVP (protótipo) | Tudo da seção 5 ✅ |
| 2. Sistema real | Banco de dados (ex.: PostgreSQL/Supabase), login, acesso de vários computadores |
| 3. Recorrência | Aulas semanais fixas (ex.: toda terça 14h), feriados |
| 4. Comunicação | Lembrete por WhatsApp/e-mail para aluno e professor |
| 5. Gestão | Relatório de aulas por professor (para pagamento), faltas, ocupação das salas |

## 7. Perguntas em aberto

- ~~Duração das aulas~~ → definido: mínimo de 1h.
- Horário de funcionamento (o protótipo usa 07h–22h).
- Alguma aula precisa de sala com recurso específico (ex.: piano)?
- Aulas em grupo (mais de um aluno) existem?
- Quem vai usar: só a recepção, ou professores também?
