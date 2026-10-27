# Como ligar o banco de dados (Supabase)

Leva uns 10 minutos e é gratuito. Pode ser feito pelo celular, mas é mais fácil no computador.

## 1. Criar o projeto
1. Entre em https://supabase.com e crie uma conta (pode usar o login do GitHub).
2. Clique em **New project**. Dê um nome (ex.: `agendamentos`), crie uma senha do banco
   (guarde-a) e escolha a região **South America (São Paulo)**.
3. Espere uns 2 minutos até o projeto ficar pronto.

## 2. Criar as tabelas
1. No menu da esquerda, abra **SQL Editor** → **New query**.
2. Copie todo o conteúdo do arquivo [`schema.sql`](schema.sql), cole e clique em **Run**.
   Deve aparecer "Success".

## 3. Criar o usuário da recepção
1. Menu **Authentication** → **Users** → **Add user** → **Create new user**.
2. Digite o e-mail e uma senha da recepção e marque **Auto Confirm User**.
3. Volte ao **SQL Editor** e rode (trocando o e-mail):
   ```sql
   insert into perfis (user_id, papel)
   select id, 'recepcao' from auth.users where email = 'recepcao@seuemail.com';
   ```

## 4. Ligar o site ao banco
1. Menu **Project Settings** → **API**. Copie:
   - **Project URL** (ex.: `https://abcdefgh.supabase.co`)
   - **anon public** key (um texto longo começando com `eyJ...`)
2. No GitHub, abra o arquivo [`config.js`](../config.js), clique no lápis (editar),
   cole os dois valores entre as aspas e clique em **Commit changes**.
   (Ou mande os dois valores para o Claude colocar.)

A chave "anon public" pode ficar pública: quem não fizer login não vê nada,
e as permissões são garantidas pelo próprio banco.

## 5. Dar acesso aos professores
1. Crie o usuário do professor como no passo 3.1–3.2 (e-mail + senha, **Auto Confirm User**).
2. Entre no site como recepção → **Cadastros** → no professor, digite o e-mail dele
   e clique em **Dar acesso**.
3. O professor entra no mesmo link com o e-mail e senha dele e vê só as aulas dele.

## Links
- Sistema: https://tfmachado19.github.io/Agendamentos/
- Exemplo (sem banco, dados só no navegador): https://tfmachado19.github.io/Agendamentos/?demo
