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
| **Professor** | id, nome, disciplinas, telefone                                        |
| **Disponibilidade** | professor, dia da semana, hora início, hora fim (o próprio professor cadastra; pode ter mais de um período por dia) |
| **Sala**      | id, nome                                                               |
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
5. **Duração mínima de 1h**, aumentando de 30 em 30 min (1h, 1h30, 2h, … até 4h).
   **Aulas individuais**: um aluno por aula (não há aulas em grupo).
   **Qualquer sala serve** (não há sala específica): o sistema pode escolher sozinho uma sala livre.
6. Aulas canceladas liberam professor e sala.
7. **Funcionamento só à tarde e à noite: 13h às 22h.**
8. **Disponibilidade do professor**: cada professor informa os dias e horários em que pode dar aula
   (ex.: segunda 13h–18h; terça 14h–16h e 19h–22h). Só é possível agendar dentro desses horários.
9. Ao escolher data/horário, o sistema **sugere só as salas e professores livres**.

## 4. Telas

1. **Agenda do dia** — grade com horários nas linhas e salas nas colunas
   (alternável para ver por professor). Cada bloco mostra aluno + professor.
2. **Novo agendamento** — data, horário, duração, aluno, professor, sala;
   avisa conflitos antes de salvar.
3. **Lista do dia** — lista em ordem de horário (boa para imprimir / recepção).
4. **Disponibilidade** — o professor marca seus dias e horários livres.
5. **Cadastros** — professores, salas e alunos.

### Quem vê o quê

| Perfil | Pode |
|--------|------|
| **Recepção** | Tudo: agenda completa, agendar/cancelar aulas, cadastros |
| **Professor** | Só **as próprias aulas e os alunos agendados com ele**, e editar a **própria disponibilidade**. Não agenda, não cancela e não vê outros professores |

## 5. Sistema

Site estático ([`index.html`](index.html)) hospedado no GitHub Pages + banco de dados
**Supabase** (PostgreSQL com login).

- **Sistema:** https://tfmachado19.github.io/Agendamentos/ — tela de login (recepção ou professor).
- **Exemplo sem banco:** https://tfmachado19.github.io/Agendamentos/?demo — dados só no navegador.
  Professor no exemplo: `?demo&professor=1`.

Enquanto o [`config.js`](config.js) estiver vazio, o site abre direto no modo exemplo.
Para ligar o banco, siga [`supabase/COMO-CONFIGURAR.md`](supabase/COMO-CONFIGURAR.md).

### Banco de dados ([`supabase/schema.sql`](supabase/schema.sql))
As regras são garantidas **pelo próprio banco**, mesmo que alguém tente burlar o site:
- Sem conflito de professor, sala ou aluno no mesmo horário (aulas canceladas não contam)
- Aulas só entre 13h e 22h, mínimo 1h, de 30 em 30 min
- Aula só dentro da disponibilidade do professor
- Professor só vê as próprias aulas e os alunos delas, e só altera a própria disponibilidade
- Aula cancelada não é apagada (fica o histórico)

### Telas
- Login (recepção / professor)
- **Agenda da semana** (domingo a sábado), de 30 em 30 min, com **cada dia dividido em uma coluna por sala**.
  Toque num horário vazio de uma sala para agendar ali; toque numa aula para cancelar.
  Horários sem nenhum professor disponível aparecem hachurados.
- Novo agendamento com verificação de conflito, salas/professores livres e "Qualquer sala livre"
- Disponibilidade por professor
- Cadastros, incluindo **Dar acesso** ao professor pelo e-mail
- Modo professor: Minhas aulas + Minha disponibilidade

## 6. Próximos passos (roadmap)

| Fase | O que entra |
|------|-------------|
| 1. MVP (protótipo) | Agenda, conflitos, disponibilidade ✅ |
| 2. Sistema real | Banco de dados (Supabase), login, acesso de vários computadores ✅ |
| 3. Recorrência | Aulas semanais fixas (ex.: toda terça 14h), feriados |
| 4. Comunicação | Lembrete por WhatsApp/e-mail para aluno e professor |
| 5. Gestão | Relatório de aulas por professor (para pagamento), faltas, ocupação das salas |

## 7. Perguntas em aberto

- ~~Duração das aulas~~ → definido: mínimo de 1h, de 30 em 30 min.
- ~~Horário de funcionamento~~ → definido: tarde e noite (13h–22h).
- ~~Sala específica~~ → definido: qualquer sala serve.
- ~~Aulas em grupo~~ → definido: só aulas individuais.
- ~~Quem usa~~ → recepção agenda; professores cadastram a própria disponibilidade
  (no sistema real, cada professor terá login próprio e só edita a sua).
