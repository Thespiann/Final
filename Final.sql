PGDMP     2    
                {           Final    15.3    15.2 @    L           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            M           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            N           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            O           1262    33433    Final    DATABASE     y   CREATE DATABASE "Final" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Greek_Greece.1253';
    DROP DATABASE "Final";
                postgres    false            �            1255    33453    check_max_players()    FUNCTION     9  CREATE FUNCTION public.check_max_players() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM player
        WHERE team = NEW.team
    ) = 11 THEN
        RAISE EXCEPTION 'Maximum number of players per team cannot be exceeded';
    END IF;
    RETURN NEW;
END;
$$;
 *   DROP FUNCTION public.check_max_players();
       public          postgres    false            �            1255    33488    check_min_days()    FUNCTION     C  CREATE FUNCTION public.check_min_days() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    min_date date;
    max_date date;
BEGIN
    SELECT date - INTERVAL '10 days', date + INTERVAL '10 days'
    INTO min_date, max_date-- the date a match could happen is this date -10 days and the max date a match could happen is this match date +10
    FROM match
    WHERE home_team = NEW.home_team OR visiting_team = NEW.home_team OR --i check for both visiting teams and home teams
          home_team = NEW.visiting_team OR visiting_team = NEW.visiting_team;

    IF min_date IS NOT NULL AND NEW.date >= min_date AND NEW.date <= max_date THEN-- if i have a match for this team before the new one im adding, i check the dates 
        RAISE EXCEPTION 'Minimum days between matches not satisfied';
    END IF;

    RETURN NEW;
END;
$$;
 '   DROP FUNCTION public.check_min_days();
       public          postgres    false            �            1255    33540 !   downgrade_team(character varying)    FUNCTION     �  CREATE FUNCTION public.downgrade_team(team_to_downgrade character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Delete rows from tables that reference the team to downgrade
	DELETE FROM game_event WHERE player_id IN (select player.id from player where player.team=team_to_downgrade);
	DELETE FROM game_event WHERE match_id IN (select match.id from match where (match.home_team=team_to_downgrade or match.visiting_team=team_to_downgrade));
	DELETE FROM minutes_per_match WHERE player_id IN (select player.id from player where player.team=team_to_downgrade);
	DELETE FROM minutes_per_match WHERE match_id IN (select match.id from match where (match.home_team=team_to_downgrade or match.visiting_team=team_to_downgrade));
	DELETE FROM match where (home_team=team_to_downgrade or visiting_team=team_to_downgrade);
	DELETE FROM manager WHERE team = team_to_downgrade;
    DELETE FROM player WHERE team = team_to_downgrade;
	
    -- Insert team into downgraded_team
    INSERT INTO downgraded_team (name, arena, description, home_wins, away_wins, home_losses, away_losses, home_draws, away_draws)
    SELECT name, arena, description, home_wins, away_wins, home_losses, away_losses, home_draws, away_draws
    FROM team
    WHERE name = team_to_downgrade;

END;
$$;
 J   DROP FUNCTION public.downgrade_team(team_to_downgrade character varying);
       public          postgres    false            �            1255    33541 !   downgrade_team_trigger_function()    FUNCTION     �   CREATE FUNCTION public.downgrade_team_trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM downgrade_team(OLD.name);
    RETURN OLD;
END;
$$;
 8   DROP FUNCTION public.downgrade_team_trigger_function();
       public          postgres    false            �            1255    33524    promote_to_manager(integer)    FUNCTION     h  CREATE FUNCTION public.promote_to_manager(player_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_minutes INTEGER;
BEGIN
    -- Calculate the total_minutes
    SELECT COALESCE(SUM(duration), 0)
    INTO total_minutes
    FROM minutes_per_match
    WHERE player_id = player_id;

    -- Insert into the manager table
    INSERT INTO manager (name, last_name, team, past_position, total_minutes)
    SELECT name, last_name, team, player_position, total_minutes
    FROM player
    WHERE id = player_id;

    -- Delete from the player table
    DELETE FROM player WHERE id = player_id;
END;
$$;
 <   DROP FUNCTION public.promote_to_manager(player_id integer);
       public          postgres    false            �            1259    33535    downgraded_team    TABLE       CREATE TABLE public.downgraded_team (
    name character varying,
    arena character varying,
    description character varying,
    home_wins integer,
    away_wins integer,
    home_losses integer,
    away_losses integer,
    home_draws integer,
    away_draws integer
);
 #   DROP TABLE public.downgraded_team;
       public         heap    postgres    false            �            1259    33491 
   game_event    TABLE     �   CREATE TABLE public.game_event (
    event_type character varying(30) NOT NULL,
    player_id integer NOT NULL,
    match_id integer NOT NULL,
    event_time time without time zone NOT NULL,
    id integer NOT NULL
);
    DROP TABLE public.game_event;
       public         heap    postgres    false            �            1259    33490    game_event_id_seq    SEQUENCE     �   CREATE SEQUENCE public.game_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.game_event_id_seq;
       public          postgres    false    222            P           0    0    game_event_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.game_event_id_seq OWNED BY public.game_event.id;
          public          postgres    false    221            �            1259    33468    match    TABLE       CREATE TABLE public.match (
    home_team character varying(20) NOT NULL,
    visiting_team character varying(20) NOT NULL,
    home_score smallint NOT NULL,
    visiting_score smallint NOT NULL,
    date date NOT NULL,
    total_duration smallint NOT NULL,
    id integer NOT NULL
);
    DROP TABLE public.match;
       public         heap    postgres    false            �            1259    33434    team    TABLE     R  CREATE TABLE public.team (
    name character varying(20) NOT NULL,
    arena character varying(30) NOT NULL,
    description text,
    home_wins smallint NOT NULL,
    away_wins smallint NOT NULL,
    home_losses smallint NOT NULL,
    away_losses smallint NOT NULL,
    home_draws smallint NOT NULL,
    away_draws smallint NOT NULL
);
    DROP TABLE public.team;
       public         heap    postgres    false            �            1259    33530    league_matches    VIEW     �  CREATE VIEW public.league_matches AS
 SELECT thismatch.total_duration AS duration,
    home_team.arena,
    thismatch.home_team AS home_team_name,
    thismatch.visiting_team AS visiting_team_name,
    thismatch.home_score,
    thismatch.visiting_score
   FROM (public.match thismatch
     JOIN public.team home_team ON (((home_team.name)::text = (thismatch.home_team)::text)))
  WHERE ((thismatch.date >= '2023-01-01'::date) AND (thismatch.date <= '2023-12-30'::date));
 !   DROP VIEW public.league_matches;
       public          postgres    false    220    220    220    220    220    220    214    214            �            1259    33456    manager    TABLE       CREATE TABLE public.manager (
    name character varying(10) NOT NULL,
    last_name character varying(10) NOT NULL,
    team character varying(20) NOT NULL,
    past_position character varying(20) NOT NULL,
    total_minutes integer,
    id integer NOT NULL
);
    DROP TABLE public.manager;
       public         heap    postgres    false            �            1259    33455    manager_id_seq    SEQUENCE     �   CREATE SEQUENCE public.manager_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.manager_id_seq;
       public          postgres    false    218            Q           0    0    manager_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.manager_id_seq OWNED BY public.manager.id;
          public          postgres    false    217            �            1259    33467    match_id_seq    SEQUENCE     �   CREATE SEQUENCE public.match_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.match_id_seq;
       public          postgres    false    220            R           0    0    match_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.match_id_seq OWNED BY public.match.id;
          public          postgres    false    219            �            1259    33508    minutes_per_match    TABLE     �   CREATE TABLE public.minutes_per_match (
    duration integer NOT NULL,
    player_id integer NOT NULL,
    match_id integer NOT NULL,
    id integer NOT NULL
);
 %   DROP TABLE public.minutes_per_match;
       public         heap    postgres    false            �            1259    33442    player    TABLE     �   CREATE TABLE public.player (
    name character varying(10) NOT NULL,
    last_name character varying(10) NOT NULL,
    team character varying(20) NOT NULL,
    player_position character varying(20) NOT NULL,
    id integer NOT NULL
);
    DROP TABLE public.player;
       public         heap    postgres    false            �            1259    33525    match_schedule    VIEW       CREATE VIEW public.match_schedule AS
 SELECT thismatch.date AS match_date,
    thismatch.total_duration AS duration,
    home_team.arena,
    thismatch.home_team AS home_team_name,
    thismatch.visiting_team AS visiting_team_name,
    thismatch.home_score,
    thismatch.visiting_score,
    (((thismatchplayer.name)::text || ' '::text) || (thismatchplayer.last_name)::text) AS player_name,
    thismatchplayer.player_position,
    minutes.duration AS player_duration,
        CASE
            WHEN (game_events.player_id = thismatchplayer.id) THEN game_events.event_type
            ELSE NULL::character varying
        END AS event_type,
        CASE
            WHEN (game_events.player_id = thismatchplayer.id) THEN game_events.event_time
            ELSE NULL::time without time zone
        END AS event_time
   FROM (((((public.match thismatch
     JOIN public.team home_team ON (((home_team.name)::text = (thismatch.home_team)::text)))
     JOIN public.team visiting_team ON (((visiting_team.name)::text = (thismatch.visiting_team)::text)))
     JOIN public.player thismatchplayer ON ((((thismatchplayer.team)::text = (thismatch.home_team)::text) OR ((thismatchplayer.team)::text = (thismatch.visiting_team)::text))))
     LEFT JOIN public.game_event game_events ON (((game_events.match_id = thismatch.id) AND (game_events.player_id = thismatchplayer.id))))
     JOIN public.minutes_per_match minutes ON (((minutes.match_id = thismatch.id) AND (minutes.player_id = thismatchplayer.id))))
  WHERE (thismatch.date = '2021-04-08'::date);
 !   DROP VIEW public.match_schedule;
       public          postgres    false    222    214    214    216    216    216    216    216    220    220    220    220    220    220    220    222    222    222    224    224    224            �            1259    33507    minutes_per_match_id_seq    SEQUENCE     �   CREATE SEQUENCE public.minutes_per_match_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.minutes_per_match_id_seq;
       public          postgres    false    224            S           0    0    minutes_per_match_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.minutes_per_match_id_seq OWNED BY public.minutes_per_match.id;
          public          postgres    false    223            �            1259    33441    player_id_seq    SEQUENCE     �   CREATE SEQUENCE public.player_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.player_id_seq;
       public          postgres    false    216            T           0    0    player_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.player_id_seq OWNED BY public.player.id;
          public          postgres    false    215            �           2604    33494    game_event id    DEFAULT     n   ALTER TABLE ONLY public.game_event ALTER COLUMN id SET DEFAULT nextval('public.game_event_id_seq'::regclass);
 <   ALTER TABLE public.game_event ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    221    222    222            �           2604    33459 
   manager id    DEFAULT     h   ALTER TABLE ONLY public.manager ALTER COLUMN id SET DEFAULT nextval('public.manager_id_seq'::regclass);
 9   ALTER TABLE public.manager ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    218    217    218            �           2604    33471    match id    DEFAULT     d   ALTER TABLE ONLY public.match ALTER COLUMN id SET DEFAULT nextval('public.match_id_seq'::regclass);
 7   ALTER TABLE public.match ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    219    220    220            �           2604    33511    minutes_per_match id    DEFAULT     |   ALTER TABLE ONLY public.minutes_per_match ALTER COLUMN id SET DEFAULT nextval('public.minutes_per_match_id_seq'::regclass);
 C   ALTER TABLE public.minutes_per_match ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    224    223    224            �           2604    33445 	   player id    DEFAULT     f   ALTER TABLE ONLY public.player ALTER COLUMN id SET DEFAULT nextval('public.player_id_seq'::regclass);
 8   ALTER TABLE public.player ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    216    215    216            I          0    33535    downgraded_team 
   TABLE DATA           �   COPY public.downgraded_team (name, arena, description, home_wins, away_wins, home_losses, away_losses, home_draws, away_draws) FROM stdin;
    public          postgres    false    227   :_       F          0    33491 
   game_event 
   TABLE DATA           U   COPY public.game_event (event_type, player_id, match_id, event_time, id) FROM stdin;
    public          postgres    false    222   W_       B          0    33456    manager 
   TABLE DATA           Z   COPY public.manager (name, last_name, team, past_position, total_minutes, id) FROM stdin;
    public          postgres    false    218   �a       D          0    33468    match 
   TABLE DATA           o   COPY public.match (home_team, visiting_team, home_score, visiting_score, date, total_duration, id) FROM stdin;
    public          postgres    false    220   c       H          0    33508    minutes_per_match 
   TABLE DATA           N   COPY public.minutes_per_match (duration, player_id, match_id, id) FROM stdin;
    public          postgres    false    224   �d       @          0    33442    player 
   TABLE DATA           L   COPY public.player (name, last_name, team, player_position, id) FROM stdin;
    public          postgres    false    216   �       >          0    33434    team 
   TABLE DATA           �   COPY public.team (name, arena, description, home_wins, away_wins, home_losses, away_losses, home_draws, away_draws) FROM stdin;
    public          postgres    false    214   Д       U           0    0    game_event_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.game_event_id_seq', 60, true);
          public          postgres    false    221            V           0    0    manager_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.manager_id_seq', 12, true);
          public          postgres    false    217            W           0    0    match_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.match_id_seq', 1, false);
          public          postgres    false    219            X           0    0    minutes_per_match_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.minutes_per_match_id_seq', 1, false);
          public          postgres    false    223            Y           0    0    player_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.player_id_seq', 1, false);
          public          postgres    false    215            �           2606    33496    game_event game_event_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.game_event
    ADD CONSTRAINT game_event_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.game_event DROP CONSTRAINT game_event_pkey;
       public            postgres    false    222            �           2606    33461    manager manager_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.manager
    ADD CONSTRAINT manager_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.manager DROP CONSTRAINT manager_pkey;
       public            postgres    false    218            �           2606    33473    match match_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.match
    ADD CONSTRAINT match_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.match DROP CONSTRAINT match_pkey;
       public            postgres    false    220            �           2606    33513 (   minutes_per_match minutes_per_match_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.minutes_per_match
    ADD CONSTRAINT minutes_per_match_pkey PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.minutes_per_match DROP CONSTRAINT minutes_per_match_pkey;
       public            postgres    false    224            �           2606    33447    player player_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.player
    ADD CONSTRAINT player_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.player DROP CONSTRAINT player_pkey;
       public            postgres    false    216            �           2606    33440    team team_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY public.team
    ADD CONSTRAINT team_pkey PRIMARY KEY (name);
 8   ALTER TABLE ONLY public.team DROP CONSTRAINT team_pkey;
       public            postgres    false    214            �           2606    33475    match unique_home_team 
   CONSTRAINT     \   ALTER TABLE ONLY public.match
    ADD CONSTRAINT unique_home_team UNIQUE (date, home_team);
 @   ALTER TABLE ONLY public.match DROP CONSTRAINT unique_home_team;
       public            postgres    false    220    220            �           2606    33477    match unique_visiting_team 
   CONSTRAINT     d   ALTER TABLE ONLY public.match
    ADD CONSTRAINT unique_visiting_team UNIQUE (date, visiting_team);
 D   ALTER TABLE ONLY public.match DROP CONSTRAINT unique_visiting_team;
       public            postgres    false    220    220            �           2620    33542    team downgrade_team_trigger    TRIGGER     �   CREATE TRIGGER downgrade_team_trigger BEFORE DELETE ON public.team FOR EACH ROW EXECUTE FUNCTION public.downgrade_team_trigger_function();
 4   DROP TRIGGER downgrade_team_trigger ON public.team;
       public          postgres    false    214    243            �           2620    33454    player trigger_max_players    TRIGGER     �   CREATE TRIGGER trigger_max_players BEFORE INSERT OR UPDATE ON public.player FOR EACH ROW EXECUTE FUNCTION public.check_max_players();
 3   DROP TRIGGER trigger_max_players ON public.player;
       public          postgres    false    228    216            �           2620    33489    match trigger_min_days    TRIGGER        CREATE TRIGGER trigger_min_days BEFORE INSERT OR UPDATE ON public.match FOR EACH ROW EXECUTE FUNCTION public.check_min_days();
 /   DROP TRIGGER trigger_min_days ON public.match;
       public          postgres    false    220    229            �           2606    33502 #   game_event game_event_match_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.game_event
    ADD CONSTRAINT game_event_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.match(id);
 M   ALTER TABLE ONLY public.game_event DROP CONSTRAINT game_event_match_id_fkey;
       public          postgres    false    220    222    3226            �           2606    33497 $   game_event game_event_player_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.game_event
    ADD CONSTRAINT game_event_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.player(id);
 N   ALTER TABLE ONLY public.game_event DROP CONSTRAINT game_event_player_id_fkey;
       public          postgres    false    3222    216    222            �           2606    33462    manager manager_team_fkey    FK CONSTRAINT     v   ALTER TABLE ONLY public.manager
    ADD CONSTRAINT manager_team_fkey FOREIGN KEY (team) REFERENCES public.team(name);
 C   ALTER TABLE ONLY public.manager DROP CONSTRAINT manager_team_fkey;
       public          postgres    false    214    218    3220            �           2606    33478    match match_home_team_fkey    FK CONSTRAINT     |   ALTER TABLE ONLY public.match
    ADD CONSTRAINT match_home_team_fkey FOREIGN KEY (home_team) REFERENCES public.team(name);
 D   ALTER TABLE ONLY public.match DROP CONSTRAINT match_home_team_fkey;
       public          postgres    false    214    3220    220            �           2606    33483    match match_visiting_team_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.match
    ADD CONSTRAINT match_visiting_team_fkey FOREIGN KEY (visiting_team) REFERENCES public.team(name);
 H   ALTER TABLE ONLY public.match DROP CONSTRAINT match_visiting_team_fkey;
       public          postgres    false    214    3220    220            �           2606    33519 1   minutes_per_match minutes_per_match_match_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.minutes_per_match
    ADD CONSTRAINT minutes_per_match_match_id_fkey FOREIGN KEY (match_id) REFERENCES public.match(id);
 [   ALTER TABLE ONLY public.minutes_per_match DROP CONSTRAINT minutes_per_match_match_id_fkey;
       public          postgres    false    224    220    3226            �           2606    33514 2   minutes_per_match minutes_per_match_player_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.minutes_per_match
    ADD CONSTRAINT minutes_per_match_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.player(id);
 \   ALTER TABLE ONLY public.minutes_per_match DROP CONSTRAINT minutes_per_match_player_id_fkey;
       public          postgres    false    3222    216    224            �           2606    33448    player player_team_fkey    FK CONSTRAINT     t   ALTER TABLE ONLY public.player
    ADD CONSTRAINT player_team_fkey FOREIGN KEY (team) REFERENCES public.team(name);
 A   ALTER TABLE ONLY public.player DROP CONSTRAINT player_team_fkey;
       public          postgres    false    3220    214    216            I      x������ � �      F   �  x�]�[n1E�9��

�"%���#�� F\��쾗���di���:]����I�b]+��}<�/�^^�7%!^�r�L���Τ�}/c��z|�>6ő�ݗ��V���ĝ�l�}�<��~�|��~ v�H�S�2e�JՃ�^���+ͅZl���mӄV�¹����8����i��s|�J�o��J�Uǀ�22"@���m����t���v$��8�K�z��o\͠j����y�n}{e����t*ɻwf�s�:�z������6#Ug#K��q���rW�+��  ��SZ�)�'7�>�e}����B>�t+zGW�p�0�N��e����8&�J}$�mAU���q��IPIՕ#�'ǀ���ts�a�<ԓQ�{�(>P���d��m�PE��D��<�s�¸��yg�' ːv�P��=��D�c�u'�L��5�eR7ӨF;�����s�'���=� ORޕ���|戋�e��vs��1���J��"������u�x��!L!5�q��{�ވ��g��a *i���ݍa`��|��o��'0�~/�g�]�|�ٚ����6��]�	�I���vB�2��&D��R��0����l���m�l���b\�=,Z�N�(��^ y'�3,i��cY���xV      B     x�u��J�@��w��O �i%�eWE*.\�	ml��Tb6����э���BK��jZ�g^ɛ��n/s�����ȱDf�����$�`�wL���(�xC�N��4�}wk��sd¨&���'�x��4�l^bޘ�Q������A�3q`����8�I��ڨ�d��@�̏�線��i�Զ�ER;�y�v��c{Kx�o�9�D+:;>1A��D�rI:O���%�'��(�~b��VZ�M�Rp���2��W��˵����EE>Dܿo����^)�%I%7�ߊQ�U      D   �  x�e��R�0��ӻ��;I�U��J**B� o����L�̮u߮N��	�����^�����?d��#NPP��5�O�;��l�����.��=��-%rB�d��k���Z!��|���I�q�<@E(a��^���!"����[�H�d<�:�f�C$K6'+��^� �փϓ$�
9G".�1�&H[NQ�BՓ\ݟ��*�Y��ۡs�ɑ��R�ȍ�^H���e'ͮ�F"�IXJ�W^�v�r�4����s\!�&قq��۱h(m[4;��*;w�B�LR{��[�)kD�`(<��G��\�c�����:s�u�,%���r���Lj�2+pv�n-Pu�Z$����l3��l��C����]H61����%[�I���S3���^ɛ��(5ޟE1^����!��?��      H      x�5�[���D�k��O�����Z�]��ހ%dJY������z����?��=?���;o5���5�o�^.���r��;��T���~�F��=�������u���P�z�k��~�sg��榹��hUw�U���r���2�����儗��4�NJJǷ�&�Q�폳�~/cե�����~�aO��nޯ�~�{�C��-U��������ǿ��v]Yv�e8~�}b��,��o��2]߿�/���;�a����z��mN,덆��o��������g�b�v�lGk���"��cG�2�(I���Q�8^��u;�DMqc�1��|��o��Я��<���q_�7S�b�Y�CDo�+����o.�����w�<F	�^�/������ƯT+�k��ǡ��У��V����[%��[�[%�q��]7��zB�X�t��5�)��z�<a����:�vM���^��	���;����S�|��y��<��	e��n�f�e�x��N��-�z��l���c�1ߩ����)i�f�Q�g�c��E�2��p.��W��1ṩ;�UV�������ׄ�}��E���S�H��+�U��}���_����{��d_ܧe^�����W���b,�ݧ�sϯ7�x�����N�ߧ����=��v�?_�);��k50d+�ѹ��x�2����n�P���i,�%��Fs�[~c�*��x����P/z��Ń�{jܹ�����輻\+<���r�w�$�<����`�W�c�cI+�Ѽ���<���>�cU���_���Ը�D��p���t��}��-W���Ė3�Ӻ�N�q˝��j��'�qˡ,�uj�r*�k�b�ȧ�-�r<�Ėc�Sb˳��<5n���9��K=��r./<�ˍ���s�G����-�^E�e]7�ͅm˷ԃ�0��+�0n����Ҹ�\6�a�r/�qv��q��-sl���Ҹ�g^%���K㖯Q�[�f�7�-�S¸�p�b��8�!1..�a0�։.���A{�[^�&�-�s��9�Yb��n���~HJ���ǲ\�L7�7���Σ�}��Jl����<���<Ϡ�������<��%�\Os���m���A�-�x��-8m�4r�ڶ��#�_�!O.��2����l���Ln?����e���w����^�hy:O���~�qEmF-�_ߩ�E�C��|��ʲo��z ��4| _ܫ^���I�]��:�\~����BxyU��}į%�\P��_�}�u�h�-��@�m �[]��3̫V��-�T{��y8����	��lV���������=�U���/ڨ`��y���-_4=1yΏ��>�G��P�/��[�H0n��A�H8�s�\�� ��3���� ^I��OD7<�L�_�O���pû�4n����|�?��|2>m;�u?m;�Dl[~h��.>I���������~_�8�|��^6��O��}ڶ\��[����1my"%�.��O��8V?����-O�	��Fj3f%���U����(�O��[�h3��'O@�mŶ�2:��Ln�.MM�͓��T��B������!|�FD5݀���'1����'�tpy��<��-x4v���5��s�t�7C�G��U��:�	q�ј�Hu������%x�͛�=V�\�DoF���h��g�b����y��T#}�����TG��[_���#ڼ����k�s,���\UO<�4�H��r�d��Z�ė岢T�����K|��]�WϑR�\�y������^�5�i��^��8���(e�^�[پ���5�A���b�w]E����X�/ʋ��U
�~#Z�X���}�u�MLV~̟e��SXVn,*фT>�%�����\nlyN	.7��%����W���5o�enu���>|ɛP��;[9�d�C�_��,&b�#/f���v(�m��R�<[�?�U�� _�[��_�4��n×�9RL#�&��ฑ��:�WP(���y ���-��-���C X��*&�+�N,��ɉ$��K'�w��ܹ���qF%t}��;
7?���^N.1sI-'�k��jy��\�����֗P�:�GG���ӭ�V�����)��ؠ	�:a���[�>W�J>�/N�䗫�M�?F�M��Ͽ{��'�F�׃�� ���� ���m��;�����Y��� w������O�{�^Z����cv0�n�|��{#����g��B��]�S�!�p�:]�pl�O��4��wu���p��;�TH��%!�#vjB�ў{�KV$� q������(_�_�4��7@iP�.�Y���r���|ݾߥ�ݚXq��;)ۏ7�-�7s\�A0�W����j��ƛ��`��;�:T{�;�� T�lLJ�'V�k��;R�{��LV��Prãʴ��ū"��$�%|��z0P)���	ګ�9�B���]
���K�R���������R՞�|�K|9��%����X%�.��Ԧ%}��Ah���3P���]%Q\��j�S���Yf��0�ay3��1;� YՓ����fr�%��U�����|_G9��]�.7ו��W�m+I��o蒿�mD��|]?�G�Id#��Kۥ�6?a�_����X������5	V��M|9���(���u"�Q�.�a������©v�8P�8�t`�a8s���Jxr\��Q��عN*7�������),���F0w���En	&�K��$~\u����R#��e΅��3%�����<ru�/�%v������~�bR��""�Y�n�H���H�>�jFv����5��?>�����kD2���XC��gT:�5M:���@�j��#�����U��Z��Ȇ����əKi������@t��g��I�Mj�o���Iv���S���{���}�0���NI//7�)����C0���8�tJ��N���t9˗�{/����35'�s�ؽ�\���7����s�[��ݬ�0�:I�Ng7ل�s$� �N�\�F�_��:��A�g�P����%z��nΥ\ܴ]���eȺb��p�DsyX��<SI&�ˊG�./��)�ə5�꜁0��Y�nd�?M�6�9�U��w�`y����������Ҡ��v L_�n�q���t��4(gw2�	�Į����h�i��V����ܦȩUۅ�]�ߟ� l���ʝ�׼��6�~���<]�!+�uS4[�/�unC�W87�yu��թY�]��ϙ(����v�*����tJ�������u�б=�.�$r\�q����}M ��%���� v��;�������N^���g,o�:뗐	���Hi��dU�s��ɺ��c��z�/�d���S���g�Q5�a�l�MA��]��������5.W���}��+1�+~]��I����(�U&^�ד�uu��i����xb�P�qx��R��D���l$o�)��7�_����tX�2%ev�:�R_��*�7�)�������^��*��{+˯�x'��R�͊��u���~[J�aU��7 �jU�ݯ�����u�_��a��]����j�{~	��ۓ��:@I._7�ol?2낖EL�kX�˭'�-��KJ�X�F.� X�%~���߽WL_.�x�`G�m���T���ӗ˻GX�8n�j�Y��> ���y�uJ���7����_�R ��g���_�$Y����pYօ��v˷���Ej�\�*_g��/������(v�<u��U���2A���eA�F.g������ҼΫ�]��;�7�X��Y�L��׭����v�/���,����M�V�f�v�?��_1�*ww��^�O֚Ű���a�9�V�;�v/w�����/w�]�����D%!m��/ߛj�N�FՎh0��\�e����ɺp�>�4vw���FuI�Ǽ�+����hW#'SP����,?� �ˑ�k��Es���|�����wD�z�]�n�S a�f��ٺ{k��N�7J�d��Wg��(o7��œ��N��w-V�߯+r��j��Y��'�OTS��V��������`���� v���]����\���Jl��V[?����]|g��哖���.!���+�������Yu�>��mw��    ׀d����V��5�ru�jb���r��]�.�;�q5���
j~�:�'��=L���=\Q2�\��i����e*_'&+�,D�����X�ک� �����͙��������a�̻&��d�,�W'_��9�{���+q�v��YN/�+��҈��{������X��|�|]n�o^�w{�+�o��}�|�vdl�]�~�̽]i��ѯ(voA�+�ݬ��� )�W��+�,�T�9w��}����ru�}�h���<݊g���y �nru��9~�]�:��Yl���v:%�K<+����n�D&.\R�N����]��G���iF+�A���g���G(M�~	�,N!i��j9�� {W���C��S�.w������SuR�$�=�eR�0���"�0N���iX�,�s(��ƞ���sV�+{����ⴸp���e����p���U�Â���T�����I����\N+�I�Y�P����Ľ�d�*_�{V⫓��b:C�K�#����S �wk����\�N�������JX��W�<�����R�S/���.�~E�g$� Şa��Q��{��ƞ�J��#g��fW;�{�	DU;`��yQ왉eE�g�وbO���Q1����j��d�E�W��`�I�e��~����\_���%���+� �$c�&.o�������q��kDv�fY���J��,Md�����k a�8R�w����gat���u�鬒�!�VM+�EC�L$,���)Qf(o����I�P~(�a��p=U!%�x�7U��I�2�1���Sn�jZ��%7�[�c$�����P�f��`O����ؽ|]=�N}����v#����&fga"�R W�kJ\ݛ���{��;׌�ř!����3g��W���c�� ���m�����Ѭ��C}J�~��~���3�ǿ���"`�~��ɬ�}�@�_?:����t�]����o���՛�(]���rt��(O����{�~o�Y`�rt�j�>^�Fݐ�+G7r}���3�û�uJ���o�#}�ª�|y������X����o+aH�����%v+A�_���S	z��U���u=M�~d�XX��]�E�_����~X �U�/UmY�����^?B�P҇��&�	��釫AI~��_g�ҥS�94�ϺD<}��ޜV��j������u���vj����g��`Z^�}=�e��|^�]��ٱ^��U���-C�~��E��[�|���߲��r����؞2O�����=n.GJ���څ��6]�ů_B�,�|�Қ.~�������^ �mf�W~ە�.���i⤬�,�&���#�);��gܻ���Ц=~g����Ǖ���;�����Ol���[�����r�rxL��_>�l��QlQ�7�9%gG�'�����B��S�+���
t]�-�}D3��R�3���q)I;;`����[��%�~�u��7A���k����b�Y�d���<�S��,���<�A�Osa�b���oz�C����sO;��*�b��uz�'���y�g���>oI}8K�>X�\�#�:�5}߭}(ꥒ����h�[g����[�����RP՞�raOm�S�py�ӭ���OS���z�a�b��G_W)'��'gM��֣�T�>���Q��Z�tbF�c:1��'�~���$��/pQ��%	�=t���.� �7�F&�xff�2�'u��B��$K��/U%�̴ذ[�̼���>s�#(Q~��t *��ę)?y��̔��^�̐��PbY@�S����R��>�����ԷS&v�e��g��Y+�%�gI�~�wn83��%#Y=�P=��g��M&���Cz�u���l3"*>׃�<�dHT��UӉ9�$�%��qu�[D��(b�ṡu��c����9���`���`���R�瘗���:"���'����)?�܉)O�r&ZP�eQ�s����!)8��ȷ����/a\�.J�rL�AB�}��$�܇�&�	#s&���;�~�5���'�l2&� b!� O�+A�P!��.^��u'�o!��u���$�\Ba����,�DOC��E2�݂lY�(Yq�\Hi+���+9��^du�vK���Gdt��p\RK�C�7�,�-D�~��O�	!w��.�fQ�g���Ưg���t��a�K�xI��j����IS�������T���~h�S�&D���̰��Q:yi$`��`>eA��a�����̐PAF�F�3b+ϡTdd4����ʪ�<'&'��nG*ܠW���3��!<}��v��I������"Y@�:'fY�߿LL�P�@��](݉YR n��EW��"�d�ĝ}���.YQ���0ĉ�b��!b�ǜJ)@sb�3zjPH%(���͉�aK=NL�eFj��q�x��-)W��1���v{�p�{�5�Jĥ�[�E�1C�G9�B�`��dZ���#�
p5^�tZ>�O#+��5>GqZ���i�HnM>�������Iy�;�|Vj����o��dW�����^�!�u�'aq����
�3�̑,(��I�y�F�'Y`�"�r8/�c��:��X��u\6j9�7��!��)l0;�JXi���T��︣�Hs�g��*���Vl����V5�Y}Y���1��U���wU^{q�K�j�Ϋ�y|��s����|�{b:sp�Q����nŁ���9z���!N���0�i�.	lP@�B��M}��ҍ�B]������f^RA�����O�3|����!%n�FVH�u��Ϙ(2�]�T�A�!4�Qn!̛5������:��S$#:/�U��f^�R��y����]_�fǛy�2 �,�4�Ѥ���9++�H��82��2s;d�B9Tk:+��?)z�%��%.'U^�e��R��,�H#�$�fNʋ�-K5�4�:'[�3%[J�H��L�ŒT�(�)��� 4�f�G
���8)�4�=T)o[��1�0��$C:'ǲ�,�5�%�LT9&�FX�����)z=����i�OB�tL����KxV�ӂ/�<�i���<˓z9:�8G�]�^��� ��r����X���`>�a�ǖd�Z�&&$��/����>ȯ0�V�t����5�UDt�JgF$�(_z��*�f����)M�0N,�M�B�i9�����&-���y;.�5�'F?��g?ē�&�C�"~�'L���ɤ�W���j���<�U��a���Y�"���T�[�z��D��$����l�'�t��8�]�pY���Ǹ����-'���q��=��%�v����{����d<W}'f���=Rv�������V~��:�^��}H)K���!=a�CKa��{*G�>�F�CL���}�)\%��r�p^
_	�>��}�}x)���a�{=*�<a��Kq �e���߳�=�a�d@�e��P�}rz�3��^�q��8'��F5qb��w&�,��G�~=8EtMƊ���\��i/�k�C�=�<g�\*^&����;3!� ~�+�c��u�~�+<�~�+L���
�?�c5μG��
e�N͑9��Wx���Wx����95�Kq.�=d��/�%ʢ�7�0��墿[Y���W�C͐hB5=��%�}I�Ͻ�
˩F��n�_8��,
b���R�I���ez{���V5�k�ׯ�Km����5+�܄��m�u����L���0��}�-��U@s/d��u�!܇��:2*4�AC��%�I�L��Ra�`��}�-+ڡ���ť)X����ͥ{���ǭ�<���a��؇�2��y�����ą�nY������[@���e��x9�I�#���84�_�tVF��b}X/ܛX�K���0Q7��#���B)���/˼�{���d9}��,�8-3�Kޜ���_�C������@�qj�>,���c���Y��qo�����y����#P�C��S����˒�8�aļ��$���Č��e���e��8���Ű (  �(և#gÉ�F/S�?���3���Yp.��$P�`f�p ��F�S��1S�3����}�1-*���;���t�pbN�����͠}H2����GR�3p��(܏Wfgt9����A��t����Uک�� ��}(3�1��O\���if*����ũa��\�.�����?>^���-?��N�>�
���Pg�`���n����`K�>ԙ� |�c�)��;�k�6,�Cq����� ~�3���˟Q��;�����G�Z�0�,9s���]��ޟ��Pi��%��=�g��3�_>��X��J�[f=S_>���t��RS�j��
�;�������D��@���f;���-��}x5��ӒL�.j3�)އY�kP�*�g����pb�!'�
L�BN
��#NJJ�f�>ԚB��	}�A�9Q��9�c���0�'����=V�̠��!B�hPm0Lо\��!�����f�Lt��@�[�:�0f�÷�ޜ�r"�Lsc�j0nr��B��7E�0n�?9%+�	�!�t���9d�7�*ĕN�>��P��̾5S����ø9rR�,�����:+[��܇x3�8jl3���(�F=���]��!�̌�*�ќ��3�Q�U�y����3o����3p�� �r\�M�h��srUɠ�5�8o�G��-�F���n#� ���!���rZ>��`.�e���FM�\C�/o�p.��� pyI�12�;1@Ǚ9�s�X":x���\�����//'���g���������[�?��:�L�3�_��Ti�.��}(:;ǐ����[������u�i�>4�7=Ti���}�:1��i�;�M����4�%>���ex:��0uxڅ�0u0�p�/�p���F:��e
�a�Osbz���}�:�=t�n�2��%��L�H�t��8�������&,C�Q%t���(��d��}g+ݙ!:��� N�ޗ��*N5C�ʐ5�"��'Fqb��3�ϲ���x���T�/�f�3ݵ�A��FE�yd:3B�A	�Sڨ0�e
�����������K�wO��U���l��J,Ӗ��e��܇���A�����KLvc�����Y�y]��a�t5qVR5��W��gо�M���.��Bg��|�kR���(;���{�����M�X��>��*�!�l;�qܴr
���d������|�Y:+xRx��J9���n�#��K�x>Q����
_^� }�>o.C	v�Q�����ԇ�i���۳%��w��x� }�?M�e�=�g�>ܟ����:/����?<�bI~�Eg����b3H_��gIm��"҇�"҇$eԭ'aw�9u�p��P�0~
�� ;(�+��
-�#{V�X#H�Jބ�A���$�:1P�C�;[��A�w�-���;�R�%����8/���9/�Ҡ�3ț��y�o٥[���A����-R�$�A=P���Ї�z�YyYD��x�E����:+Cν�l6BL�H��f�n�6E����H�#���|f�>!^� }8B�� }XB�i��(�@}�B+��c�u��M��g�>��	�	���!m�91+��`}hC�sb�?ԇ74�� ���������i�,��3H�P,��l��U�[$��aAR����&�ߖJ��e�<�^�}�C�#����-���`h�*�l/�v���B� }D=�P"զ�m��#�=�fc���{�Iv�Ɇ>QA�#}q��(ʐN8_����5�PR��� ��sۧ����/s^��rN̗]6��e����5�z���C.����K.Z�|�Eܛ8rZ��!MO�Jx
��!��8r��Op�
·]$Sܙ�_t�_��jP���h����h����4�m+@�ѫ��H�̬� }�F=�P%է+@���L��/�
Їs�s]^�ܺd�W$�����ԅL���a�$�f?V���#uqfzv]�C>B�P����P����V\doZ�G����a13b}�G ����]��
և~��e��vR#���a ��؇��s%����M5�9��݋\��C���Ȧ>��9/�$m��Hj��P+�c�2�?C��V��}XI]q�˴�b�l$����ݚ6hj��D�˲j~	��&��xn���&���s�p^X����`�^��$���˲�.;`�l�m�$l�/A鳇۔v�#k����ye�O��w3$�JG����:�
��������85�2�u�h8�[��m��{���-�r�K\�u����]�$�f���j�&U�!�5�K�뜚�r�%䇾�������������E����̰�l���l��|��x��k�_L�y��������~���Caڹ����])<]���u���p���ai���iz�(�z���%s�m���n(Ь�\��r�b24ɞ!�6XM=Ф��S��k�j)�/���}�M|,��P��
��6q7�}�M|���_��K����T���Ź��p��%�]q_7�_�}�M�2Ѡ���������i8B�=fC��+'�)`�K�����S�e����؇�4��i�߽-�%5X��IM ��A�ħ�U�Aw��vV��wM�����o���Y�,W����i����2M:,�>�'�P��b_'%��-�>�'>�B}8OL�P�Ӷ�
3��X��s��vr�C{�=�X��iIp��%?�z,�.����z��d�����k_������l)h+`�s3�����4X"�=E���;-;��j��l��
և��LT!{�e����~����[�      @   �  x����n�F���S�	
�&�K�i�H�]��n��N��r�-��jɅ��@ȥE(h7�
�W������3�8�E�����w���E���?b.R��5�_�a�//�5����N㋨ݍ:�������l7\�21��C~«X��,?��>�4�����#�b"n�VCq�m&źo���\�Ӫ����?��cq�/����/�.~���OԑX4�+|@��9��k�޺E��N#t�3�&>b�LnB��!�����N�nCմ=#���nG;Q�I�s�J׍����e�l���I��U�aȆ��g)��n��76I���q!�|m��{���5G��1n�ó���d�30gW�$ �1�w��Ȧ�����9Y�w��nu��V�h��*^"[r�r9�o�V��
q1�A{��#q�̻.W�qA�[��ަr���t�Ъ��&>2�끕�� �ko�g#N�|�.���[��8!��<�/��k�W���pO�ILx�O�_A�i�>����
=�&���V�a�ʄ:?�Q�>���ވ+��GZ6��9	���}�_h#0b�Jw�˔˨X� ��gx�1�K������@��-i���Q�+1$����^��R�%e�[ &��"�ᵲ]H;_�k�^`���� �_e�D ����Rt)J��2��͈�+���9_CF5�$�w��7��� ��&�Cǣ�q�wN��V�GU>��\q�yW@ �%Sv���?=�[������>Ҏ���_�#�^�b?��s���ʼTt&6>�0��\��!�!3]k��4�8���L/!El��(�?�X����y=rS�4��XR�EU�k���G�iS	P�Z[/KS./"@�O�at)�U��;��.����ҷ�<ī.�����PA!�F1ݱdo�hlub� $�E1���jn@�׵&PAS�z���uV��u�}J�[a
�0Q�S��h��X)������(/��	׌���K�nC	L���ˈ*圅�����{pa��
�з�V�;�ɥ(�u^�Sn����04��>��۵��pyU>�i�fW��RlE#\7���T[�7�㚿 �^�#/`�	éR�<��)u-M�P|i�٫]�D��0H�iJNdļ�^��:��Z��������f�G|ʔ'iR�CjMS�`�+UP�����u�¥�t~��q�� C7��      >   �   x�%��j�0���S�	FWg�ӭ�!�2�]��KD<�X.%o?9�� ������B=ڞ	������b*x���4F�3E���+K�X�I�B��}�������N�LW�[��ۀM�>����q�I6�^oT�ֿ+ᨔ�s�H-&$YpQHG9�pK�l��}x���P�3uң6x5�I����1N�E�9o�N�{��2_�>Е���b�c�	�H2��^���[��<c��b&     