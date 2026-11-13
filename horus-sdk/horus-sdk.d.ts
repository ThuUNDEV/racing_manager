/*! Horus SDK 0.21.1 | (c) Horus Entertainment */
// Types of the Horus SDK 0.21.1. In a script tag: the global HorusSDK; as a module: import from './horus-sdk.mjs'.
export as namespace HorusSDK;

export const VERSION: string;
/** the horus-gamekit release this SDK was built from */
export const KIT: string;

export interface StartOptions {
  /** the cloud save (true) */
  cloud?: boolean;
  /** ms the start waits for the cloud save's answer (3000) */
  cloudWait?: number;
  /** store products whose prices the game shows (platform.iap.price) */
  skus?: string[];
  [option: string]: unknown;
}

/** Starts the SDK once, before the game's first frame: the cloud save, then platform.init; resolves with the platform. */
export function start(opts?: StartOptions): Promise<Platform>;

export type Target = 'web' | 'android' | 'ios';
/** the core's events; a plugin may add its own ('cloud': @horus/cloudsave) */
/** (0.40.0) platform.hot's state */
export interface HotStatus { on: boolean; active: string | null; pending: string | null; off: boolean; checking: boolean }

export type PlatformEvent = 'pause' | 'resume' | 'ads' | 'adpaid' | 'purchase' | 'insets' | 'prices' | 'notif' | 'shortcut' | 'ua' | 'games' | 'gamesPlay' | 'trim' | 'gamemode' | 'thermal' | 'update' | (string & {});

export interface Purchase {
  sku: string;
  token: string;
  orderId: string;
  acknowledged?: boolean;
  /** 'purchased' only once the purchase passed the check (Play's signature, the verify server); 'pending': a payment
   * that has not cleared, or (reason 'verifying') a purchase not checked yet. Refused purchases are left out. */
  state?: 'purchased' | 'pending';
  reason?: string;
  /** a licence tester's purchase (verify server) or any in a debug build: keep it out of real revenue */
  test?: boolean;
}

export interface BuyResult {
  /** 'ok': paid and checked; 'pending': the payment has not cleared, or (reason 'verifying') the purchase could not be
   * checked yet, it comes through pending() later; 'invalid': the check refused it (a fake purchase), grant nothing */
  status: 'ok' | 'pending' | 'cancel' | 'owned' | 'invalid' | 'error';
  sku: string;
  token?: string;
  orderId?: string;
  /** 'verifying' with status 'pending'; why with status 'invalid' (signature, consumed, other_install...) */
  reason?: string;
  /** with status 'ok': a licence tester's purchase (verify server) or any in a debug build */
  test?: boolean;
}

/** support.diag(): what the app knows about itself and its SDKs, for a support email (android; a browser has less). */
export interface SupportDiag {
  /** the library version of the Android shell */
  shell?: string;
  /** installer: 'com.android.vending' for Google Play, '' when it was put on by hand */
  app?: { name?: string; package?: string; version?: string; build?: number; debug?: boolean; installer?: string };
  /** android: Android version and SDK level, maker, model, WebView version, language; web: the browser's user agent */
  device?: { android?: string; sdk?: number; maker?: string; model?: string; webview?: string; lang?: string; ua?: string };
  /**
   * each SDK module in the build: applovin { sdk, initialized, sdkKey (set), rewarded, interstitial, rvReady, interReady,
   * region, privacyOptions }, adjust { initialized, environment, appToken, purchaseEvent, purchaseTestEvent },
   * facebook { sdk, initialized, appId, logging }, firebase-* { initialized }, billing { ready, checks }; a plugin's
   * module its own (cloudsave { on, server, state, gen, syncedAt }: @horus/cloudsave)
   */
  modules?: Record<string, Record<string, unknown>>;
}

export interface Reminder {
  /** the reminder's kind; comes back as `kind` in notif.opened / the 'notif' event and the notif_open event */
  id: string;
  /** when to show it, ms since epoch */
  at: number;
  title: string;
  body: string;
  /** (0.7.0) the game's screen to open when the player taps it; comes back in notif.opened / the 'notif' event */
  screen?: string;
  /** (0.7.0) the channel, which the player can turn off on its own in Android's settings: 'rewards' (default),
   * 'comeback' (bringing back a player who has been away), 'news' (Firebase pushes) */
  channel?: 'rewards' | 'comeback' | 'news';
  /** (0.7.0) how many things wait in the game: the count of the launcher icon's badge (0: none) */
  number?: number;
}

/** (0.7.0) The notification the player tapped: notif.opened (it started the app) or the 'notif' event (the game ran). */
export interface NotifOpen {
  kind: string;
  screen: string;
  /** when the game planned it for, ms since epoch (0: unknown) */
  at: number;
  /** when it went up, ms since epoch (0: unknown) */
  shownAt: number;
  openedAt: number;
}

/** (0.38.0) What platform.share.open carries. image: a png / jpeg / webp data: URL (canvas.toDataURL), at most 8 MB. */
export interface ShareContent {
  title?: string;
  text?: string;
  url?: string;
  image?: string;
}

/** (0.38.0) platform.share.open's answer. */
export type ShareResult =
  | { ok: true; via: 'sheet' | 'copy'; app: string }
  | { ok: false; reason: 'cancel' | 'unsupported' | 'error' };

/** (0.15.0) A home-screen shortcut (a long press on the app icon: iOS Quick Actions, Android app shortcuts). */
export interface Shortcut {
  /** what the game gets back when the player picks it */
  id: string;
  /** in the game's language; Android shows this line only (about 25 characters fit) */
  title: string;
  /** iOS: a smaller second line */
  subtitle?: string;
  /** 'mail' | 'heart' | 'play' | 'star' (iOS also takes an SF Symbol name; Android: none for other names) */
  icon?: 'mail' | 'heart' | 'play' | 'star' | (string & {});
}

/** (0.15.0) The shortcut the player picked: shortcuts.opened (it started the app) or the 'shortcut' event (the game ran). */
/** (0.26.0) The Games app's "play this": a Game Center activity (or a challenge's) the player tapped, by the game's key. */
export interface GamesPlay {
  /** the activity's key (Game Center id without sdk.games.idPrefix) */
  activity: string;
  /** the activity's properties from App Store Connect, e.g. { map: '3' } */
  properties: Record<string, string>;
}

export interface ShortcutOpen {
  id: string;
  openedAt: number;
}

/** (0.7.0) What Android allows now (notif.state). supported false: a browser, or a shell before 0.7.0. */
export interface NotifState {
  supported: boolean;
  /** notifications can show: the permission (Android 13+) and the app's switch */
  enabled: boolean;
  /** each channel's switch: rewards, comeback, news */
  channels: Record<string, boolean>;
  /** notif.ask() would show Android's dialog; false once the player refused it for good (then only settings()) */
  canAsk: boolean;
}

/** (0.8.0) What platform.use hands a plugin's setup (js/plugin.js). */
export interface PluginApi {
  readonly kind: Target;
  /** the platform object, to add the plugin's part to */
  readonly platform: Platform;
  /** a bridge call (BRIDGE.md); fallback when there is no answer in time (at once on the web) */
  call<T = unknown>(method: string, args?: object, fallback?: T, timeoutMs?: number): Promise<T>;
  /** a bridge message without an answer (nothing on the web) */
  post(method: string, args?: object): void;
  /** the save mirror goes to native now */
  flushSave(): void;
  /** the save waiting to be mirrored is dropped (the plugin replaces the save) */
  dropSave(): void;
  /** during platform.init, alongside save.read and rc.values; { backup } becomes platform.save.backup (app.info is {} on the web).
   * Added after init (platform.use too late): it runs at once, its backup is not used */
  onInit(fn: (appInfo: Record<string, any>, initOpts: Record<string, any>) => void | null | { backup?: string | null } | Promise<void | null | { backup?: string | null }>): void;
  /** a native event before the game's handlers: the data they get (undefined: as it is, null: dropped) */
  mapEvent(event: string, fn: (data: any) => any): void;
  /** after the game's handlers (for 'pause': after the save flush); from: what 'resume' comes back from ('bg', 'ad', '') */
  after(event: string, fn: (data: any, extra: { from: string }) => void): void;
  /** the SDK Status line(s) of a support email for app.diag modules[module] */
  reportLine(module: string, fn: (state: Record<string, any>, helpers: { utc(ms: number): string; val(v: unknown): string }) => string | string[]): void;
}

/** (0.8.0) A part of the platform API in a package of its own: platform.use(cloudSave()) of @horus/cloudsave. */
export interface PlatformPlugin {
  name: string;
  setup(api: PluginApi): void;
}

/** (0.24.0) platform.ads.ready() and the 'ads' event */
export interface AdsReady {
  rv: boolean;
  inter: boolean;
  /** the revenue estimate of the rewarded ad a show would take, USD for one impression (-1: none or not known) */
  rvValue: number;
  interValue: number;
  /** its network (MAX's name: 'AppLovin', 'Google AdMob', ...), '' when none */
  rvNet: string;
  interNet: string;
}

/** (0.24.0) the 'adpaid' event: an ad impression MAX paid for (app only; Firebase, Adjust and Facebook get it too) */
export interface AdPaid {
  /** USD for this impression */
  value: number;
  network: string;
  kind: 'rv' | 'inter';
  placement: string;
  /** MAX's revenue precision: 'publisher_defined', 'exact', 'estimated', 'undefined' */
  precision: string;
  /** '' the main ad unit, else the extra unit's tag */
  tag: string;
}

export interface Platform {
  readonly kind: Target;
  /** the app's name (launcher label), version, build number, device language, debug build (filled by init in the app) */
  /** modules: the SDK modules in the app's build ('applovin', 'adjust', 'billing', 'facebook', 'firebase-analytics', 'firebase-crashlytics', 'firebase-messaging', 'firebase-remoteconfig', 'integrity'; 'cloudsave' of @horus/cloudsave); [] on the web */
  /** tampered (0.10.0, webgame-integrity): a release build signed by a certificate not in sdk.integrity.certSha256 (a modified copy); false on the web and without the module */
  readonly info: { name: string; version: string; build: number; lang: string; debug: boolean; modules: string[]; tampered: boolean; /** (0.25.0) the system text size, 1 = default (Android font scale, iOS Larger Text); 1 on the web */ fontScale?: number };
  /** (0.8.0) the names of the plugins in use (platform.use) */
  readonly plugins: string[];
  /**
   * (0.8.0) adds a part of the API from a package of its own, before init: platform.use(cloudSave()) of @horus/cloudsave
   * gives platform.cloud. A second plugin with the same name is ignored. Returns the platform.
   */
  use(plugin: PlatformPlugin): Platform;
  /**
   * call once before the game starts: app info, insets, the save backup, Remote Config, what the plugins do at start
   * (the cloud save's check), store prices. The options go to the plugins too (cloudWait: @horus/cloudsave).
   */
  init(opts?: { skus?: string[]; [option: string]: unknown }): Promise<void>;
  /** 'pause' {reason: 'bg' | 'ad'}, 'resume', 'ads' AdsReady & {privacy}, 'adpaid' AdPaid (0.24.0, app only), 'purchase' Purchase, 'insets', 'prices', 'notif' NotifOpen, 'shortcut' ShortcutOpen, 'ua' (platform.ua), 'games' {signedIn}, 'gamesPlay' GamesPlay (0.26.0), 'trim' {tier: 'hidden' | 'critical' | 'low', level} (0.27.0, Android: free GPU memory you can rebuild on 'resume'); a plugin's ('cloud' CloudState: @horus/cloudsave) */
  on(event: PlatformEvent, fn: (data: any) => void): void;
  /** the game is on screen: the app drops its splash */
  ready(): void;
  /** the Android back gesture: return true when the game used it, false lets the app go to the background */
  onBack(fn: () => boolean): void;
  /** send the app to the background */
  exit(): void;

  ads: {
    /** GDPR region: show a "Privacy settings" button that calls ads.privacy() */
    hasPrivacy: boolean;
    /** what is loaded; (0.24.0) with the loaded ads' revenue estimates and networks (-1 / '' on the web and before a load) */
    ready(): AdsReady;
    /**
     * Load now if that format is neither loaded nor loading (omitted: both). The app already loads one of each at start,
     * the next one as soon as an ad closes, and retries a failed load 2 s ... 64 s later: call this when the game is
     * about to offer an ad (a result card with x2, the shop), so a waiting retry goes at once. Readiness: ready() and
     * the 'ads' event.
     */
    load(kind?: 'rv' | 'inter'): void;
    /**
     * (0.24.0) the tags of the extra ad units in the app's settings (sdk.applovin.rewardedExtra / interstitialExtra:
     * [{ id, tag }]); [] without any, and on the web
     */
    tags: string[];
    /**
     * (0.24.0) the extra ad units whose tags load from now on ('*': all of them); a show then takes the ready ad with the
     * highest revenue estimate, the main unit's on a tie. Until the game calls this (or with []) the app runs on the main
     * ad units alone. An extra unit that fails 3 loads in a row rests 10 minutes. Nothing on the web.
     */
    units(tags: string[] | '*'): void;
    /**
     * (0.24.0) the player's MAX segments (MAX dashboard > Segment Targeting): { key: value | values }, whole numbers.
     * The app keeps them and MAX applies them from the next start (it reads segments only when it starts). {}: none.
     */
    setSegments(segments: Record<number, number | number[]>): void;
    /**
     * web only: the game's placeholder ad, (kind, placement) => Promise<watched>. opts.loadMs: the placeholder's load
     * time (at start and after each ad; 0 = always ready), to try the game's loading states in a browser.
     */
    simulate(present: (kind: 'rewarded' | 'inter', placement: string) => Promise<boolean>, opts?: { loadMs?: number }): void;
    rewarded(placement: string): Promise<{ ok: boolean; reason: '' | 'closed' | 'not_ready' | 'error' }>;
    inter(placement: string): Promise<{ shown: boolean }>;
    privacy(): Promise<unknown>;
    /** android: AppLovin MAX's Mediation Debugger, for testing the integration (shown: false until MAX has started; always false on the web) */
    mediationDebugger(): Promise<{ shown: boolean }>;
  };

  /**
   * (0.24.0) Asks the store for its own rating dialog: Google Play In-App Review (Android), the App Store's review
   * prompt (iOS). Resolves once the flow is over. shown true means the store was asked: neither Google nor Apple says
   * whether the dialog really appeared (they limit how often it shows, and Google shows nothing to an app not installed
   * from Play), so never reward a rating or ask "did you rate us?". Call it after a good moment (a won level), not from
   * a button. Needs the review module (platform.info.modules includes 'review'); without it and on the web
   * { shown: false }.
   */
  review(): Promise<{ shown: boolean }>;

  /**
   * (0.25.0) Game services: Google Play Games (Android), Game Center (iOS), with the games module
   * (webgame.config.json sdk.games: Play's projectId and the Play ids of the game's keys; Game Center uses the keys,
   * with sdk.games.idPrefix). Boards and achievements are named by the game's own keys. Calls while signed out are
   * dropped: on the 'games' event { signedIn: true } send the bests and the unlocks again (both stores keep a board's
   * best and ignore a second unlock). On the web and without the module nothing happens.
   */
  games: {
    /** the build has the games module */
    readonly available: boolean;
    /** the player is signed in to Play Games / Game Center ('games' event when it changes) */
    readonly signedIn: boolean;
    /** a score for the board `board` (a whole number, 0 or more) */
    submit(board: string, score: number): void;
    /** unlocks the achievement `id` */
    unlock(id: string): void;
    /** the store's own leaderboards (one board when given) or achievements screen */
    show(what?: 'leaderboards' | 'achievements', board?: string): Promise<{ shown: boolean }>;
    /** sign in again, from a button the player tapped (Android shows Play's sheet) */
    signIn(): Promise<boolean>;
    /** iOS: the Game Center access point on (menu) or off (play); Android: nothing */
    access(on: boolean): void;
    /** (0.26.0) iOS 26 Game Center: challenges (built on the boards) and activities; false on Android and older iOS */
    readonly social: boolean;
    /** Game Center's screen to challenge friends: the challenge `id` (a game key), or all challenges and activities */
    challenge(id?: string): Promise<{ shown: boolean }>;
    /** the activity `id` (a game key) starts (on) or ends: a run on the map it stands for */
    activity(id: string, on: boolean): void;
    /** what the player picked in the Games app before the game listened; later ones come as the 'gamesPlay' event */
    readonly play: GamesPlay | null;
    /** platform.games.play, taken once (null after) */
    takePlay(): GamesPlay | null;
    /** (0.27.0) Play Games Game Stats (Level Up) is on: Android with sdk.games.projectId; false on iOS and the web */
    readonly stats: boolean;
    /**
     * (0.27.0) a Game Stats event `name` as defined in Play Console, with its properties. Whole numbers go as integers
     * unless the property is in sdk.games.decimals. Play sends the batch when the game leaves the screen. Signed out:
     * dropped. Level Up's progression stat is the event 'progressUpdate' with { currentProgress }.
     */
    stat(name: string, props?: Record<string, number | string | boolean>): void;
    /** (0.30.0) Play Games Recall is there: Android with sdk.games.projectId; false on iOS and the web */
    readonly recall: boolean;
    /**
     * (0.30.0) a Play Games Recall session id of the signed-in player, for the game's server (it asks Google which of
     * the game's accounts the player had on another phone; @horus/cloudsave 1.7.0 does this by itself). '' when signed
     * out, without Recall, or when Play gave none. Use it soon: it does not keep.
     */
    recallSession(): Promise<string>;
  };

  iap: {
    /** true in an app with the billing module: call pending() at start and from a "Restore purchases" button */
    restorable: boolean;
    /** the store's price string for the player's country, or null (use your own) */
    price(sku: string): string | null;
    buy(sku: string): Promise<BuyResult>;
    pending(): Promise<Purchase[]>;
    /**
     * after the goods are in the save: consume (consumable) or acknowledge (one-time item). usd (0.10.0): the product's
     * price in USD from the game's own price table, for the ltv_revenue user property (without it only Play prices in
     * USD count)
     */
    finish(p: { sku: string; token: string; orderId?: string; consumable: boolean; usd?: number }): void;
    /**
     * (0.11.0) the "Restore purchases" button (App Review asks for one on iOS when the game sells a non-consumable):
     * iOS syncs the player's App Store account (it may ask them to sign in); Android and the web have nothing to sync.
     * Then call pending() and grant what it holds. -> true when the sync went through
     */
    restore(): Promise<boolean>;
  };

  /**
   * Analytics. The library sets the standard user properties itself: connection_type, config_version (Remote Config's
   * config_version, '0' without one) at init; in the app also purchase_count, ltv_revenue (USD) and ua_network,
   * ua_campaign, ua_adgroup, ua_creative (Adjust's attribution). On the web, what is logged before the page has gtag /
   * dataLayer waits for them (100 events at most).
   */
  an: {
    /** Firebase Analytics in the app (gtag / dataLayer on the web). Flat params: numbers and short strings */
    log(name: string, params?: Record<string, string | number | boolean>): void;
    user(props: Record<string, string | number | null>): void;
    /** (0.10.0) a run (level, match) ended: sets win_streak and lose_streak, kept on the device between sessions */
    result(won: boolean): void;
    /** (0.10.0) the player's amount of a resource: '<name>_balance' (coin -> coin_balance), sent at most every 2 s */
    balance(name: string, amount: number): void;
    /** (0.11.0) Firebase's earn_virtual_currency { virtual_currency_name, value, source }: value rounded, nothing at 0 or less */
    earn(currency: string, value: number, source?: string): void;
    /** (0.11.0) Firebase's spend_virtual_currency { virtual_currency_name, value, item_name }: value rounded, nothing at 0 or less */
    spend(currency: string, value: number, item?: string): void;
    /** (0.10.0) send the balances waiting now (done for you when the app goes to the background) */
    flush(): void;
    /** Tracking off on this phone (a tester's: the game's isNative): nothing more is sent; the app keeps it across
     * launches and holds back ad and purchase revenue for Firebase, Adjust and Facebook too */
    block?(on: boolean): void;
  };

  /**
   * (0.10.0) Where the install came from (Adjust's attribution, app only): null until Adjust knows it (it can come
   * during the first session, platform.on('ua')). Remote Config can also differ by campaign: a condition on the user
   * property ua_campaign; the first session has the defaults, the next start the campaign's values.
   */
  readonly ua: { network: string; campaign: string; adgroup: string; creative: string } | null;

  /** Remote Config values activated for this session, as strings */
  rc: { values: Record<string, string> };

  save: {
    /** the copy of the save the app keeps outside the WebView (restore it when localStorage is empty) */
    backup: string | null;
    /** hand the app the latest save JSON (sent at most every 1.5 s, and right away on pause) */
    mirror(json: string): void;
    flush(): void;
  };

  /**
   * Support (a "Contact support" button in the game's Settings): the support ID, the app's state, the player's email
   * app. contact() does it all, the way Horus' Unity games do.
   */
  support: {
    /** the player's support ID, "A1B2-C3D4-E5F6" (the shell's from 0.8.0, every app has one; '' in a browser, or with a
     * shell before 0.8.0 without the cloudsave module): show it in Settings; the admin page of the cloud save server
     * (@horus/cloudsave) finds the player's save by it */
    id: string;
    /** (0.8.0) the plugins' SDK Status lines, by module (PluginApi.reportLine) */
    lines: Record<string, (state: Record<string, any>, helpers: { utc(ms: number): string; val(v: unknown): string }) => string | string[]>;
    /** (0.45.1) one line under Shell in SDK Status: what the game's JS was built with (@horus/sdk: "Horus SDK: <v> (kit <v>)") */
    about: string;
    /** what the app knows about itself and its SDKs */
    diag(): Promise<SupportDiag>;
    /** the diag as the "--- SDK Status ---" lines of a support email */
    report(d: SupportDiag): string;
    /** opens the player's email app with this email written (they send it). reason: 'address' | 'no_app' */
    mail(m: { to: string; subject: string; body: string }): Promise<{ ok: boolean; reason?: string }>;
    /**
     * the support email: subject "<app> - <version> - <build> - Android - USERID: <id>", body greeting (default "Hi
     * there! My support ID is <id>."), room for the player's message, the SDK Status lines. offline (default true):
     * answer reason 'offline' without opening anything when the phone has no network (show a no-internet message)
     */
    contact(o: { to: string; app?: string; greeting?: string; offline?: boolean }): Promise<{ ok: boolean; reason?: 'offline' | 'address' | 'no_app' | string }>;
  };

  notif: {
    /** (0.7.0) the notification the player tapped to start the app, or null; a tap while the game runs: 'notif' event */
    opened: NotifOpen | null;
    /** asks for the notification permission (Android 13+) */
    ask(): Promise<boolean>;
    /** replaces whatever was planned before */
    schedule(list: Reminder[]): void;
    /** cancels what was planned and takes the one on screen down (the launcher's badge with it) */
    cancelAll(): void;
    /** (0.7.0) what Android allows now */
    state(): Promise<NotifState>;
    /** (0.7.0) opens the app's notification settings: only from a switch the player taps */
    settings(): void;
  };

  /**
   * (0.15.0) Home-screen shortcuts: what a long press on the app icon shows above "Remove app" (iOS Quick Actions,
   * Android 7.1+ app shortcuts), such as "Having an issue? Let us know" and "Don't go! Let's play again". The app shows
   * them from the first set() on, until the next one; the app logs shortcut_open {id} when the player picks one.
   */
  shortcuts: {
    /** false on the web, on Android before 7.1 and with a shell before 0.15.0 */
    supported: boolean;
    /** the shortcut the player picked to start the app, or null; one picked while the game runs: 'shortcut' event */
    opened: ShortcutOpen | null;
    /** replaces the app's shortcuts (at most 4; [] removes them). Call after init and after a language change */
    set(list: Shortcut[]): void;
  };

  /**
   * (0.38.0) The phone's share sheet with a picture, a line of text and a link (a result card, a challenge, an invite).
   * Android: the system chooser (ok once it opened: Android never says what the player did next); iOS: the share sheet
   * (app = the activity type the player picked); the web: navigator.share, else the text and link copied (via 'copy').
   * A shell before 0.38.0 uses the WebView's navigator.share or the clipboard.
   */
  share: {
    /** the shell has app.share (0.38.0); on the web: the browser can share or copy */
    supported: boolean;
    open(o: ShareContent): Promise<ShareResult>;
  };

  /** ms, or [on, off, on, ...] ms like navigator.vibrate */
  haptic(p: number | number[]): void;

  /**
   * (0.29.0) Google Play in-app updates (the update module, Android; iOS and the web: nothing available). check():
   * a newer version on Play, its priority (0-5, set per release) and how many days this one is stale; start(false):
   * Play asks, downloads in the background ('update' { state: 'downloading', pct } ... { state: 'downloaded' }), then
   * complete() at a menu restarts on the new version; start(true): Play's full-screen update (for priority >= 4 or a
   * very old version).
   */
  update: {
    readonly state: 'none' | 'downloading' | 'downloaded' | 'installing';
    check(): Promise<{ available: boolean; versionCode: number; priority: number; staleDays: number; flexible: boolean; immediate: boolean }>;
    start(immediate?: boolean): Promise<{ started: boolean }>;
    complete(): void;
  };

  /**
   * (0.40.0) Hot update (HOT.md): a newer web build of the game (JS, HTML, assets, never native code) from Horus's hot
   * update server, without a store release. Off unless webgame.config.json has hotUpdate.url and hotUpdate.key; the
   * web: always off. The shell checks by itself a few seconds after app.ready and downloads in the background; the
   * new version runs from the next start. A version whose game does not reach app.ready (twice, or 45 s on screen)
   * goes back to the app's own web build by itself.
   */
  hot: {
    /** hot update is set up in this app */
    readonly on: boolean;
    /** the hot update version the page runs (its manifest id), null for the app's own web build */
    readonly active: string | null;
    /** a version downloaded and ready: used at the next start, or now with apply() */
    readonly pending: string | null;
    /** the server has nothing for this store build: the app's own web build from the next start */
    readonly off: boolean;
    readonly checking: boolean;
    status(): Promise<HotStatus>;
    /** asks the server now (a Tools page's button); resolves when the download, if any, is done */
    check(): Promise<HotStatus>;
    /** the pending version now: the page reloads (the save is kept), so call it at a menu only */
    apply(): Promise<{ applied: boolean }>;
  };

  /**
   * (0.28.0) Android: what the device says, for the game's quality tiers. gameMode: the Game Dashboard's choice
   * (Android 12+; 'battery': cap fps, drop effects; 'performance': the top tier), 'gamemode' event { mode } when it
   * changes. thermal: Android 10+ status, headroom (Android 11+, 1.0 = severe throttling, -1 unknown), 'thermal' event
   * when it moves: step effects down before the phone throttles. exits: how the last runs ended when Android ended
   * them ('low_memory', 'anr', 'crash', 'crash_native', 'excessive_resource', 'signaled'... each once), for analytics.
   * iOS and the web: 'unsupported', 'unknown', [].
   */
  readonly device: {
    readonly gameMode: 'standard' | 'performance' | 'battery' | 'custom' | 'unsupported';
    readonly thermal: { status: 'none' | 'light' | 'moderate' | 'severe' | 'critical' | 'emergency' | 'shutdown' | 'unknown'; headroom: number };
    readonly exits: { reason: string; at: number; foreground: boolean; pssKb: number; rssKb: number }[];
    /** (0.33.0) Android 6+: the screen's refresh rate now and the rates its modes offer at this resolution (0 / []: unknown) */
    readonly display: { hz: number; modes: number[] };
    /**
     * (0.33.0) Android: a Firebase Test Lab device, which the Play pre-launch report uses too. The shell already blocks
     * tracking there (Firebase Analytics, Adjust, Facebook) and shows no ads; the game may skip its own pop-ups.
     */
    readonly robot: boolean;
    /**
     * (0.33.0) Android: switch the screen to its mode nearest at or above hz (60: a 90/120/144 Hz panel refreshes at 60,
     * requestAnimationFrame comes at 60: half the frames and less panel power); 0 gives the choice back to the system.
     * Resolves to the rate the screen runs at now (0: the shell cannot; iOS and the web: 0, WKWebView draws at 60).
     */
    setFrameRate(hz: number): Promise<{ hz: number }>;
  };
  /**
   * (0.33.0) Android: Firebase Test Lab's Game Loop test started the app (scenario from the test's --scenario-numbers).
   * The game plays its own benchmark and calls done(report): the report (text, JSON) goes to Test Lab's results file
   * and the app closes, which ends the test. null otherwise.
   */
  readonly testLoop: { scenario: number; done(report: string): Promise<{ written: boolean }> } | null;
  /** (0.28.0) Android 13+ Game State: in a menu, in play (a run), or showing content (an ad, a video); loading a level */
  gameState(mode: 'menu' | 'play' | 'content', loading?: boolean): void;
  /** a JS error for Crashlytics (non-fatal) */
  crash(message: string, stack?: string): void;
  /**
   * (0.10.0) keys a crash report shows (Crashlytics custom keys, app only): the save slot, the level, the screen. Flat
   * values; the library already sets wg_shell, wg_modules, save_bytes, save_at and every user property
   */
  crashKeys(keys: Record<string, string | number | boolean | null>): void;

  /** game-specific native methods registered with WebGame.register(...) in Kotlin */
  native: {
    call<T = unknown>(method: string, args?: object, fallback?: T, timeoutMs?: number): Promise<T>;
    post(method: string, args?: object): void;
  };
}

export const target: Target;
export const platform: Platform;
export function createWeb(): Platform;
export function createAndroid(bridge?: { post(json: string): void }): Platform;

/** start() turns the cloud save on (@horus/cloudsave's plugin) */
export interface Platform {
  cloud: cloud.Cloud;
}

/** The cloud save: status words for a Settings line, and the rules that settle the phone's save against the cloud's. */
export namespace cloud {
  /** The cloud save: platform.cloud.boot, cloud.status() and the 'cloud' event. */
  export interface CloudState {
    /**
     * off: no cloud save (module not in the build, no server url, a browser); offline: no answer from the server (yet);
     * none: nothing on the server yet; pending: a save waits for a network; synced: the server has this phone's save;
     * error: the server refused the last save (too large...), the next save tries again;
     * restore (boot): the phone had no save of its own, the cloud copy is back and save.backup holds it;
     * conflict: the server has a different save (a reinstall that started offline, an old backup restored): data is the
     * cloud copy, and nothing goes up until the game calls cloud.useCloud() or cloud.keepLocal()
     */
    state: 'off' | 'offline' | 'none' | 'pending' | 'synced' | 'error' | 'restore' | 'conflict';
    /** when this phone last sent or took a save, ms since epoch (0: never) */
    syncedAt: number;
    /** restore / conflict: the server's generation of its save */
    gen?: number;
    /** restore / conflict: when the cloud copy was saved, ms since epoch */
    savedAt?: number;
    /** restore / conflict: the cloud copy (the save JSON) */
    data?: string;
    /** conflict: the cloud copy is an admin's change (the admin page): take it over this phone's save (useCloud), adding
     * back what was bought on the phone, and tell the player */
    force?: boolean;
    /** (1.7.0) a conflict with the save of the player's other phone (Play Games Recall), on a new install */
    recall?: boolean;
  }

  /**
   * platform.cloud. The game keeps playing on its own save; the app sends each save.mirror once there is a network
   * (within sdk.cloudsave.uploadDelay, 2 minutes; right away when the app goes to the background). Handle boot.state
   * 'conflict' and the 'cloud' event with state 'conflict': nothing goes up until the game decides. A conflict with force
   * is an admin's change: take it (useCloud).
   */
  export interface Cloud {
    /** the build has the cloudsave module with a server url (after platform.init; always false in a browser) */
    enabled: boolean;
    /** what the start-up check found (platform.init) */
    boot: CloudState;
    status(): Promise<CloudState>;
    /** a conflict: the cloud copy becomes the save -> its JSON (null: no conflict waiting); load it, then save */
    useCloud(): Promise<string | null>;
    /** a conflict: this phone's save goes up over the cloud copy (save what you merged in from it first) */
    keepLocal(): Promise<void>;
    /** send the newest save now (after a purchase) rather than within uploadDelay */
    sync(): void;
  }


  export const BOOT_WAIT: number;
  export function cloudState(r: unknown): CloudState;
  /** the plugin. wait: ms platform.init waits for the server when the phone has no save (default 3000); init({ cloudWait }) overrides it */
  export function cloudSave(opts?: { wait?: number }): PlatformPlugin;

  /** "2 days ago" ('' without a time) */
  export function ago(t: number, nowMs?: number): string;
  export interface StatusWords {
    synced: string | ((syncedAt: number) => string);
    offline: string;
    none: string;
    error: string;
    conflict: string;
    off: string;
  }
  export const STATUS_WORDS: StatusWords;
  /** a Settings line for platform.cloud.status() */
  export function statusText(s: CloudState | null | undefined, words?: Partial<StatusWords>): string;

  /** The game's rules for a conflict (README.md). */
  export interface ConflictRules<S> {
    /** the phone's save JSON, null when there is none */
    read(): string | null;
    /** a save, null when the JSON is not one of the game's */
    parse(json: string | null | undefined): S | null;
    /** a went further than b */
    further(a: S, b: S): boolean;
    /** what `into` takes from `from` whichever is kept (purchases it lacks); returns what was added */
    merge(into: S | null, from: S | null): number;
    /** the save becomes `save`: the game's storage and platform.save.mirror + flush */
    adopt(save: S): void;
  }
  export interface Settled<S> {
    took: 'cloud' | 'local';
    /** an admin's change, taken whichever went further */
    forced: boolean;
    /** what merge added */
    added: number;
    local: S | null;
    /** the cloud copy (with took 'cloud': the one taken) */
    cloud: S | null;
  }
  /** at start: a boot conflict settled (null: nothing to decide) */
  export function settleAtBoot<S>(platform: Platform, rules: ConflictRules<S>): Promise<Settled<S> | null>;
  /** while playing, the player chose the cloud copy: true when it became the save (reload next) */
  export function takeCloud<S>(platform: Platform, rules: ConflictRules<S>, current: S | null, fallback: S | null): Promise<boolean>;
}

/** A versioned local save: defaults filled in, migrations, gathered writes, the app's backup copy. */
export namespace save {
  export const VERSION: string;

  /** The part of the Web Storage API the store uses. */
  export interface StorageLike {
    getItem(key: string): string | null;
    setItem(key: string, value: string): void;
    removeItem(key: string): void;
  }

  export interface EconomyReset<S> {
    /** the save field holding the economy version ('econ') */
    field?: string;
    version: number;
    /** reset what an older economy earned (coins, upgrades...); `fresh` is a new default save */
    reset(save: S, fresh: S): void;
  }

  export interface PartVersions<S> {
    /** one version per part (a map); a stored value that differs (missing counts as 1) resets that part */
    versions: number[];
    reset(save: S, index: number): void;
  }

  export interface SaveStoreOptions<S extends object> {
    key: string;
    /** a fresh default save; called for every load and wipe */
    defaults(): S;
    /** the save format, stored as `v` (1); a stored save with another `v` is not loaded */
    version?: number;
    economy?: EconomyReset<S> | null;
    /** field name -> per-part versions (Hill Sling: { mapv: ... }) */
    parts?: Record<string, PartVersions<S>>;
    /** runs on the stored object before it is filled in */
    before?: ((stored: any) => void) | null;
    /** runs on the filled save */
    after?: ((save: S, stored: any) => void) | null;
    /** keys never written */
    omit?: string[];
    /** ms queue() gathers writes over (400) */
    delay?: number;
    /** (globalThis.localStorage); null: none (nothing is stored) */
    storage?: StorageLike | null;
    /** called with every written JSON (@horus/webgame's platform.save.mirror) */
    mirror?: ((json: string) => void) | null;
    /** (1.1.0) every written save carries "_seal" (a hash of it and key); load() reports a save edited outside the game */
    seal?: { key: string; onBroken?: (info: { state: 'broken' | 'missing'; save: S }) => void } | null;
  }

  export interface SaveStore<S extends object> {
    readonly key: string;
    /** on false: nothing is written (?nosave); mirror can be set later */
    readonly persist: { on: boolean; mirror: ((json: string) => void) | null };
    readonly current: S | null;
    load(): S & { v: number; econReset?: 1 };
    /** write now; false when nothing was stored */
    save(save?: S): boolean;
    /** write after `delay` ms, the last one wins */
    queue(save: S): void;
    /** a queued write now; true when one was waiting */
    flush(): boolean;
    wipe(): S;
    /** an app's backup copy back into an empty storage, before load() */
    restoreBackup(json: string | null | undefined): boolean;
    /** a stored JSON parsed, null when it is not a save of this format */
    parse(json: string | null | undefined): (S & { v: number }) | null;
    stringify(save: S): string;
    readRaw(): string | null;
    writeRaw(json: string): boolean;
    /** (1.1.0, with seal) the last load() found a save edited outside the game */
    readonly sealBroken: boolean;
  }

  /** (1.1.0) the seal of a save's JSON under key (28 hex characters) */
  export function sealOf(json: string, key: string): string;
  /** (1.1.0) json with "_seal" added as its last key */
  export function addSeal(json: string, key: string): string;
  /** (1.1.0) what a stored JSON's seal says */
  export function checkSeal(raw: string | null | undefined, key: string): 'ok' | 'broken' | 'none';

  export function createSaveStore<S extends object>(o: SaveStoreOptions<S>): SaveStore<S>;
  /** `saved`'s values over `defaults` (in place, to any depth); wrong kinds fall back to the default */
  export function fill<T extends object>(defaults: T, saved: unknown): T;
  export function fitArray<T>(a: unknown, n: number, pad: T | ((i: number) => T)): T[];

  /** a went further than b, by the first field (dotted path or getter) on which they differ */
  export function further<S = any>(...fields: Array<string | ((s: S) => unknown)>): (a: S, b: S) => boolean;

  export interface MergePurchasesOptions<S = any, B = any> {
    /** the purchase list's field ('buys') */
    list?: string;
    /** the purchase's store token field ('token') */
    token?: string;
    /** the purchase's time field ('t') */
    time?: string;
    /** how many purchases a save keeps (30); 0: all */
    keep?: number;
    /** boolean fields copied when true in `from` */
    flags?: string[];
    /** give `into` the goods of `buy`; returns the amount credited, or false for an unknown product (skipped) */
    credit(into: S, buy: B): number | false | null | undefined;
  }
  export function mergePurchases<S = any>(into: S | null, from: S | null, o: MergePurchasesOptions<S>): number;

  /** The rules object of @horus/cloudsave's settleAtBoot / takeCloud (ConflictRules). */
  export interface ConflictRules<S> {
    read(): string | null;
    parse(json: string | null | undefined): S | null;
    further(a: S, b: S): boolean;
    merge(into: S | null, from: S | null): number;
    adopt(save: S): void;
  }
  export function conflictRules<S extends object>(store: SaveStore<S>, o: {
    further(a: S, b: S): boolean;
    merge(into: S, from: S): number;
    /** platform.save.mirror */
    mirror?: (json: string) => void;
    /** platform.save.flush */
    flush?: () => void;
  }): ConflictRules<S>;
}

/** When an interstitial may show, waiting for a rewarded ad, the short-of-coins steps, Remote Config overrides (no SDK calls: the game calls platform.ads). */
export namespace monetize {
  export const VERSION: string;

  export type ConfigTarget = Record<string, number | string | boolean>;
  /** "k:v,k:v" pairs; a comma ends a value only before the next key */
  export function parsePairs(q: string | null | undefined): Array<[string, string]>;
  /**
   * Remote Config "<group>_<key>" values and query-string groups (?group=k:v,...) over the targets, each key to its
   * default's kind. Returns what was set.
   */
  export function applyConfig(
    groups: Record<string, ConfigTarget>,
    rc?: Record<string, unknown> | null,
    query?: { get(name: string): string | null } | Record<string, string | undefined> | null,
    o?: { all?: string[]; min?: number },
  ): Array<[string, string, number | string | boolean]>;

  export interface InterRules {
    interOnX2Skip: number;
    interFromRun: number;
    interEvery: number;
    interCooldown: number;
    sessionWarmup: number;
    rewardedGrace: number;
    rvWaitMs: number;
  }
  export const INTER_DEFAULTS: Readonly<InterRules>;
  export interface PacingState { inter: number; interRun: number; lastInter: number; lastRewarded: number; watched: number }
  export function pacingState(): PacingState;
  export interface InterContext {
    /** ms (the game's clock) */
    now: number;
    runs: number;
    noAds?: boolean;
    /** a game rule says no (Hill Sling: the first session before Map 1 is cleared) */
    block?: boolean;
    x2Skipped?: boolean;
    /** s since the session started */
    sinceStart: number;
    /** s, instead of interCooldown (an A/B group) */
    cooldown?: number;
    /** s, instead of sessionWarmup */
    warmup?: number;
  }
  export type InterWhy = '' | 'no_ads' | 'blocked' | 'x2_taken' | 'early' | 'every' | 'warmup' | 'cooldown' | 'rewarded';
  export function interDue(state: Partial<PacingState> | null, rules: Partial<InterRules>, ctx: InterContext): { due: boolean; why: InterWhy };
  export function noteInter(state: Partial<PacingState>, runs: number, now: number): void;
  export function noteRewarded(state: Partial<PacingState>, now: number): void;
  /** @horus/webgame's platform.ads, or anything with ready() (and load()) */
  export interface AdsLike { ready(): { rv?: boolean }; load?(kind: string): void }
  export function waitRewarded(ads: AdsLike, o?: { waitMs?: number; poll?: number; gone?: () => boolean; clock?: () => number }): Promise<'ready' | 'timeout' | 'gone'>;

  export interface ShortConfig { afterBuys: number; freeAds: number; gemStep: number; adsForGems: number; maxSteps: number; pin: number; fromRun: number }
  export const SHORT_DEFAULTS: Readonly<ShortConfig>;
  export function shortStep(n: number, cfg?: Partial<ShortConfig>): { gems: number; ads: number };
  export interface ShortView { open: boolean; step: number; gems: number; ads: number; prog: number }
  export interface ShortLadder {
    readonly state: { buys: number; step: number; prog: number; first: string | null };
    reset(): void;
    view(runs: number): ShortView;
    pinned(): boolean;
    focus(lastTapped: string | null | undefined, canUp?: (id: string) => boolean): string | null;
    bought(id: string, how: 'coin' | 'gem' | 'ad'): void;
    adWatched(runs: number): { done: boolean; prog: number; ads: number };
  }
  /** cfg is read at every call: pass the game's live config object */
  export function createShortLadder(cfg?: Partial<ShortConfig>): ShortLadder;

  export interface OfferWindow { shown: number; at: number; until: number; bought: number; boughtAt: number; expired: number; day: string; dayN: number; key: string; closedAt?: number }
  export interface OfferState { last: number; o: Record<string, OfferWindow> }
  export interface OfferCtx { now: number; runs: number; day: string; playS1?: number; key?: string | number; [k: string]: unknown }
  export interface OfferCfg { on: number | boolean; minSecs?: number; gapRuns?: number; [k: string]: unknown }
  export interface OfferDef<C extends OfferCtx = OfferCtx, F extends OfferCfg = OfferCfg> {
    id: string; once?: boolean;
    /** a trigger name when the offer may pop up now, else '' */
    when(ctx: C, o: OfferWindow, cfg: F): string;
    /** window length in hours (0 or none: no countdown) */
    hours?(cfg: F): number;
    on?(cfg: F): unknown;
  }
  /** the offers' state inside the save (created on first use) */
  export function offerState(save: { offers?: Partial<OfferState> }): OfferState;
  export function isOpen(st: OfferState, def: OfferDef<any, any>, now: number): boolean;
  /** every open window, soonest to close first */
  export function openOffers(st: OfferState, defs: OfferDef<any, any>[], now: number): { id: string; until: number }[];
  /** windows that closed unbought since the last call (each one once) */
  export function expired(st: OfferState, defs: OfferDef<any, any>[], now: number): { id: string; shown: number }[];
  /** the offer to pop up now, or null */
  export function due<C extends OfferCtx, F extends OfferCfg>(st: OfferState, defs: OfferDef<C, F>[], cfg: F, ctx: C): { id: string; trigger: string } | null;
  /** the pop-up went up: count it, open its window; returns how many times it has shown */
  export function shown<C extends OfferCtx, F extends OfferCfg>(st: OfferState, def: OfferDef<C, F>, cfg: F, ctx: C): number;
  export function bought(st: OfferState, def: OfferDef<any, any>, ctx: { now: number }): void;
  export function offerGet(st: OfferState, id: string): OfferWindow;
}

/** Retention logic on small state objects the game keeps in its save: clock, A/B, sessions, offline income, daily gifts, chests, missions, the local notification plan, analytics with an FTUE funnel. */
export namespace liveops {
  export const VERSION: string;

  /** ms in an hour / a day. */
  export const HOUR: number;
  export const DAY: number;

  export interface Clock {
    /** ms added to the base time (a dev "time travel" offset) */
    shift: number;
    now(): number;
  }
  export function createClock(o?: { shift?: number; base?: () => number }): Clock;
  /** The module's shared clock: the default of every `now`. Set `clock.shift` to move the module's time. */
  export const clock: Clock;

  /** 'YYYY-MM-DD' of t in the device's time zone. */
  export function dayKey(t?: number): string;
  /** Local midnight that starts the day. */
  export function dayStart(key: string): number;
  /** Calendar days from a to b (DST-safe). */
  export function dayDiff(a: string, b: string): number;
  export function msToMidnight(t?: number): number;
  /** Local time on the calendar day n days after t's, at minute m of that day. */
  export function atDay(t: number, n: number, m: number): number;
  export function minuteOf(t: number): number;
  export function nextHour(t: number): number;
  /** "3h 05m" or "4:09". */
  export function fmtLeft(ms: number, units?: { h?: string; m?: string }): string;
  /** "40 s", "12 min", "3 h 12 min", "6 d 2 h". */
  export function fmtDur(ms: number, units?: { s?: string; min?: string; h?: string; d?: string }): string;
  /** Rounds a reward to a clean shop number (steps 5 ... 50000). */
  export function shopRound(c: number): number;

  export interface Experiment {
    variants: readonly string[];
    /** one per variant; missing: 1 each */
    weights?: readonly number[];
    [k: string]: unknown;
  }
  /** Assigns each experiment once (keeps a listed variant). Returns the keys assigned now. */
  export function assignAB(ab: Record<string, string>, experiments: Record<string, Experiment>, rnd?: () => number): string[];

  export interface MetaState {
    installAt: number;
    installDay: string;
    sessions: number;
    sessionStart: number;
    lastSeen: number;
    /** day indexes played (the latest keepDays) */
    days: number[];
    /** runs this session: the game counts them */
    sessionRuns: number;
    /** 1 once the player came back 24-48 h after install */
    back24: number;
    /** session starts [day index, minute of the day] (the notification planner's) */
    hours: [number, number][];
    [k: string]: unknown;
  }
  export function createMeta(): MetaState;
  export function bootMeta(m: Partial<MetaState>, t?: number): MetaState;
  export function dayIndex(m: Partial<MetaState>, t?: number): number;
  export function noteSessionStart(m: Partial<MetaState>, t?: number, keep?: number): void;
  export interface Resume {
    away: number;
    fresh: boolean;
    day: number;
    newDay: boolean;
    prev: { sess: number; len: number; runs: number } | null;
  }
  export function resumeSession(m: Partial<MetaState>, o?: { now?: number; sessionGap?: number; keepDays?: number; keepHours?: number }): Resume;
  export function pauseSession(m: Partial<MetaState>, t?: number): { len: number; runs: number };

  export interface OfflineState { pending: number; hours: number; [k: string]: unknown }
  export interface OfflineConfig {
    /** coins per hour (the game's number) */
    rate: number;
    /** hours counted, at most (8) */
    capH?: number;
    /** ms away before anything accrues (5 min) */
    minAway?: number;
    /** hours' worth before offlineReady (0.25) */
    showH?: number;
  }
  export function createOffline(): OfflineState;
  export function offlineCap(cfg: OfflineConfig): number;
  export function accrueOffline(s: OfflineState, away: number, cfg: OfflineConfig): number;
  export function offlineReady(s: OfflineState, cfg: OfflineConfig): boolean;
  export function offlineAt(s: OfflineState, lastSeen: number, t: number, cfg: OfflineConfig): number;
  export function claimOffline(s: OfflineState, mult?: number): { coins: number; hours: number };

  export interface CalendarState { day: number; last: string; claims: number; [k: string]: unknown }
  export type Rewards<R> = readonly R[] | ((index: number) => R);
  export function createCalendar(): CalendarState;
  export function calendarInfo<R>(s: CalendarState, rewards: Rewards<R>, o?: { now?: number; days?: number }): { day: number; claimable: boolean; rewards: R[]; claims: number; nextIn: number };
  export function claimCalendar<R>(s: CalendarState, rewards: Rewards<R>, o?: { now?: number; days?: number }): { day: number; index: number; reward: R } | null;

  export interface ChestState { readyAt: number; opens: number; adDate: string; adOpens: number; [k: string]: unknown }
  export interface ChestConfig<R = unknown> {
    /** ms between free opens (4 h) */
    every?: number;
    /** ad opens a calendar day (3) */
    adOpens?: number;
    reward?: R | (() => R);
  }
  export function createChest(): ChestState;
  export function chestInfo(s: ChestState, cfg?: ChestConfig, o?: { now?: number }): { ready: boolean; left: number; adLeft: number; readyAt: number };
  export function openChest<R = true>(s: ChestState, cfg?: ChestConfig<R>, o?: { now?: number; viaAd?: boolean; reward?: R | (() => R) }): R | null;

  /** The welcome-back gift is due (days calendar days away, at most once every `every` days). */
  export function giftDue(g: { lastSeen?: number; givenAt?: number; waiting?: unknown }, t?: number, cfg?: { days?: number; every?: number }): boolean;

  export interface MissionDef<C = any> {
    tier?: number;
    /** the target for this ctx */
    n?: (ctx: C) => number;
    text?: (n: number, ctx: C) => string;
    gems?: number;
    reward?: unknown;
    /** a ctx key that must be truthy */
    needs?: string;
    /** progress keeps the best single amount */
    max?: boolean;
  }
  export interface Mission { id: string; n: number; prog: number; gems: number; done: number; claimed: number; text: string; reward?: unknown }
  export interface MissionsState { date: string; list: Mission[]; bonus: number; [k: string]: unknown }
  export function seededRandom(str: string): () => number;
  export function createMissions(): MissionsState;
  export function ensureMissions<C>(s: MissionsState, defs: Record<string, MissionDef<C>>, ctx?: C, o?: { now?: number; seed?: string | number }): { carried: number; carriedList: Mission[]; list: Mission[] } | null;
  export function missionProgress(s: MissionsState, kind: string, amount?: number, defs?: Record<string, MissionDef>): Mission[];
  export function missionsInfo(s: MissionsState, o?: { now?: number }): { list: Mission[]; ready: number; allClaimed: boolean; bonus: number; refreshIn: number };
  export function claimMission(s: MissionsState, i: number): { id: string; gems: number; reward: unknown } | null;
  export function claimMissionBonus(s: MissionsState): boolean;

  export interface NotifyConfig {
    window: string;
    bounds: string;
    learn: number;
    keep: number;
    lead: number;
    fallback: number;
    merge: number;
    cap: number;
    comeback: string;
    quiet: number;
    /** minutes: a return this soon after a reminder counts as a response (0: taps only) */
    respond: number;
    off: string;
    [k: string]: unknown;
  }
  export const NOTIFY_DEFAULTS: Readonly<NotifyConfig>;
  export interface PlayWindow {
    /** local hours reminders may go out in */
    hours: Set<number>;
    /** minute of the day for reminders not tied to a moment */
    main: number;
    learned: boolean;
  }
  export function playWindow(starts: readonly (readonly number[])[] | undefined, cfg?: Partial<NotifyConfig>, fixed?: boolean): PlayWindow;
  export function firstAllowed(win: PlayWindow, t: number): number;
  export function windowText(win: PlayWindow): { main: string; hours: string; learned: boolean };
  export interface NotifyState { plan: { k: string; at: number }[]; ignored: number; [k: string]: unknown }
  export function createNotify(): NotifyState;
  export function noteReturn(s: NotifyState, t?: number, tapped?: string, o?: { respond?: number; enabled?: boolean }): void;

  export type Candidate =
    | { kind: string; at: number; optional?: boolean }
    | { kind: string; day: number | readonly number[]; optional?: boolean };
  export interface PlannedItem {
    kind: string;
    /** every kind merged into this reminder, by priority */
    kinds: string[];
    at: number;
    /** comeback reminders: the days away */
    away?: number;
  }
  export interface Planned extends PlannedItem {
    title: string;
    body: string;
    screen: string;
    channel: string;
    number?: number;
  }
  export interface PlanOptions {
    now?: number;
    /** meta.hours */
    starts?: readonly (readonly number[])[];
    /** notify.ignored */
    ignored?: number;
    config?: Partial<NotifyConfig>;
    candidates?: readonly Candidate[];
    priority?: readonly string[];
    comebackKinds?: readonly number[];
    comebackPrefix?: string;
    text?: (item: PlannedItem) => { title: string; body: string } | null | undefined;
    screen?: ((kind: string) => string) | Record<string, string>;
    channel?: (kind: string) => string;
    number?: (at: number, item: PlannedItem) => number;
    fixed?: boolean;
    cap?: number;
    comeback?: string | readonly number[];
    off?: string | readonly string[];
  }
  export interface Plan {
    list: Planned[];
    dropped: { kind: string; at: number; why: 'off' | 'quiet' | 'late' | 'cap' }[];
    win: PlayWindow;
    quiet: boolean;
  }
  export function planNotifications(o?: PlanOptions): Plan;
  /** @horus/webgame Reminder objects for platform.notif.schedule() (its channels: give `channel` one of these). */
  export function toReminders(plan: Plan | readonly Planned[]): { id: string; at: number; title: string; body: string; screen: string; channel: 'rewards' | 'comeback' | 'news'; number?: number }[];
  /** For notify.plan in the save. */
  export function planRecord(plan: Plan | readonly Planned[]): { k: string; at: number }[];
  /** Remote Config (`${prefix}<key>`) and a 'k:v,k:v' query over target's own keys. Mutates and returns target. */
  export function applyConfig<T extends object>(target: T, rc?: Record<string, unknown> | null, prefix?: string, query?: string): T;

  export type Params = Record<string, string | number>;
  export interface AnalyticsState { log: { n: string; t: number; p: Params }[]; counts: Record<string, number>; ftue: Record<string, number>; [k: string]: unknown }
  export interface Sink {
    log?(name: string, params: Params): void;
    user?(props: Record<string, string | number | null>): void;
  }
  export interface Analytics {
    readonly state: AnalyticsState;
    readonly log: AnalyticsState['log'];
    readonly counts: Record<string, number>;
    track(name: string, params?: Record<string, unknown>): Params;
    onTrack(fn: (name: string, params: Params) => void): () => void;
    ftue(step: string): boolean;
    setUserProps(props: Record<string, string | number | null>): void;
  }
  export function cleanParams(p: Record<string, unknown>): Params;
  export function createAnalytics(o?: {
    state?: Partial<AnalyticsState> | Record<string, unknown>;
    ctx?: () => Record<string, unknown>;
    /** the game's build tag: a `build` param on every event */
    build?: string;
    sink?: Sink | null;
    now?: () => number;
    installAt?: number | (() => number);
    steps?: readonly string[];
    max?: number;
    debug?: boolean | ((name: string, params: Params) => void);
  }): Analytics;

  export interface CodesState { used: string[]; [k: string]: unknown }
  export function createCodes(): CodesState;
  export function normCode(s: unknown): string;
  export type CodeEntry = { from?: number | string; to?: number | string; [reward: string]: unknown };
  export function codeTable(table: unknown): Record<string, CodeEntry>;
  export type RedeemResult =
    | { ok: true; code: string; reward: Record<string, number> }
    | { ok: false; code: string; why: 'empty' | 'unknown' | 'used' | 'early' | 'expired' | 'nothing' };
  export function redeemCode(s: Partial<CodesState>, input: string, table: unknown, o?: { now?: number; caps?: Record<string, number>; never?: readonly string[]; keep?: number }): RedeemResult;
}

/** Price curves with shop rounding, BEST BUY, a seeded economy simulator. */
export namespace economy {
  export const VERSION: string;

  /** [limit, step]: the first row whose limit is above the price rounds it to that step; 'floor-even' floors to even */
  export type RoundingTable = ReadonlyArray<readonly [number, number | 'floor-even']>;
  export const ROUNDING: { readonly shop: RoundingTable; readonly even: RoundingTable };
  export function roundPrice(c: number, table?: RoundingTable): number;
  export function priceCurve(o: { base: number; growth: number; round?: RoundingTable | ((c: number) => number) }): (level: number) => number;
  export function growthFor(from: number, to: number, levels: number): number;

  export interface BuyCandidate { id: string; lv: number; cost: number; /** 'hill', '+N' (metres), '' */ pred?: string }
  export function bestBuy<C extends BuyCandidate>(cands: C[], o?: { coins?: number; any?: boolean; order?: string[]; key?: (c: C) => number; bigGain?: number }): C | null;

  export interface RunResult { dist: number; fin: boolean; /** s */ t: number }
  export type Levels = Record<string, number>;
  export interface SimOptions {
    maps: number;
    upgrades: string[];
    run(map: number, upg: Levels, ctx: { runs: number; boost?: number }): RunResult;
    pay(map: number, r: RunResult, ctx: { best: number; upg: Levels }): number;
    pick(map: number, upg: Levels, coins: number, any: boolean, ctx: { runs: number }): { id: string; c: number } | null;
    max?(id: string, map: number): number;
    length?(map: number): number;
    clearGems?(map: number): number;
    start?: { coins?: number; gems?: number };
    ladder?: { afterBuys?: number; fromRun?: number; pin?: number; maxSteps?: number; maxAds?: number; step(n: number): { gems: number; ads: number } } | null;
    inter?: { fromRun: number; every: number; fromMap?: number } | null;
    boost?: { fromRun: number; pick(rnd: () => number): number } | null;
    boosted?(upg: Levels, k: number, map: number): Levels;
    time?: { ad?: number; inter?: number; between?: number; runCap?: number };
    maxRuns?: number;
    profiles?: Array<'noads' | 'some' | 'ads'>;
  }
  export interface MapResult { runs: number; dry: number; /** s */ t: number; /** % of the map each run reached */ ds: number[]; /** upgrades bought after each run */ per: number[]; upg: string; left?: number; stuck?: true }
  export interface ProfileResult { maps: MapResult[]; runs: number; minutes: number; gems: number; rv: number; inter: number; gemUps: number; adUps: number; boostRuns: number }
  export function simulateEconomy(o: SimOptions): Record<string, ProfileResult>;
  export function playProfile(o: SimOptions, profile: 'noads' | 'some' | 'ads'): ProfileResult;
  export function economyReport(res: Record<string, ProfileResult>): string;
}

/** three.js at 60 fps on mid phones: quality governor, frame pacer, frame stats, device info. */
export namespace perf {
  export const VERSION: string;


  export interface GovernorOptions {
    /** Number of quality tiers; 0 is the best, higher tiers are cheaper. */
    tiers: number;
    /**
     * Starting tier (0). It is also the best tier a retest climbs back to; raises on a high frame
     * rate are not limited by it.
     */
    start?: number;
    /** Tiers that look identical on this screen: never stepped into (default: none). */
    same?: (a: number, b: number) => boolean;
    /** Called when the tier changes (not for the starting tier). */
    apply?: (tier: number) => void;
    /** A 1 s window under this fps is slow (55). */
    low?: number;
    /** A 1 s window at or over this fps is good (58.5). */
    high?: number;
    /**
     * The frame loop does blank frames (1.1): on every requestAnimationFrame while `wantsBlank` it
     * draws nothing and calls `blank(now)` instead, before FramePacer. Lets the governor tell a
     * browser frame-rate cap (iOS Low Power Mode, an iOS frame from another site before a tap,
     * energy savers: 30 fps) from a slow game, and work against the cap. Default false: the
     * governor never asks for blank frames and behaves as in 1.0.
     */
    capProbe?: boolean;
    /** The cap was found (its fps) or is gone (0); also after a recheck() that found it still there. */
    onCap?: (cap: number) => void;
  }

  /**
   * Picks the best quality tier the device holds at ~60 fps, from frame rates alone, without
   * mistaking a 30 fps cap, a CPU-bound frame or noise for a GPU that needs less. The rules are in
   * the README ("Quy tắc của governor") and at the top of src/governor.js.
   */
  export class QualityGovernor {
    constructor(o: GovernorOptions);
    /** Number of tiers. */
    readonly n: number;
    readonly start: number;
    same: (a: number, b: number) => boolean;
    apply: (tier: number) => void;
    low: number;
    high: number;
    /** false after fix(tier), true after fix(null). */
    readonly auto: boolean;
    /** The current tier (change it with fix() or set()). */
    readonly tier: number;
    /** Frames per second of the last 1 s window (measured with a fixed tier too). */
    readonly fps: number;
    /** Tier changes so far. */
    readonly changes: number;
    /** The loop does blank frames (option capProbe). */
    capProbe: boolean;
    /** Called when the cap is found (fps) or gone (0). */
    onCap: (cap: number) => void;
    /**
     * The browser's frame-rate cap found by the blank probe, in fps (30, sometimes 20), or 0. While
     * capped, windows are slow under 90% of it and good from 97.5% (or `low` and `high` if lower),
     * and the governor never raises above the tier it had when the cap was found. It is looked at
     * again 2 minutes after it was found and then every 4 minutes, soon after the page was hidden,
     * when a quarter of a window's frames come under 25 ms (not again for 1, 2, 4, then 8 minutes
     * after each probe that found it still there), and on recheck(); a window 25% over it clears it
     * at once. reset() and fix() keep it.
     */
    readonly cap: number;
    /** Blank probes run so far (4 blank frames each). */
    readonly probes: number;
    /** Draw nothing this frame and call blank(now) instead (a probe for a frame-rate cap: 4 frames). */
    readonly wantsBlank: boolean;
    /** On every requestAnimationFrame while `wantsBlank`, instead of drawing, before FramePacer. */
    blank(now: number): void;
    /**
     * Probe again at the next window (needs capProbe): after the first tap, which lifts WebKit's cap
     * on an embedded page, or to look for a cap now. When capped afterwards, onCap is called even if
     * the value did not change. A probe the loop skips (it draws instead) is asked again 30 s later.
     */
    recheck(): void;
    /** Sets the cap by hand (fps, or 0 for none), e.g. from a game that knows; calls onCap on a change. */
    setCap(fps: number): void;
    /**
     * Once per drawn frame (after the frame pacer). `now`: ms (performance.now() or the
     * requestAnimationFrame timestamp). `live`: false while loading or paused; `hidden`: the page
     * is hidden (document.hidden). Those frames are not counted.
     */
    frame(now: number, live?: boolean, hidden?: boolean): void;
    /** A fixed tier (a player's choice in a menu), or back to automatic from `start` with null. */
    fix(tier: number | null | undefined): void;
    /** Switches to `tier` now (clamped), keeping the mode; low level, prefer fix(). */
    set(tier: number): void;
    /** The next tier down (1) or up (-1) that changes something; `tier` itself when none does. */
    stepFrom(tier: number, dir: 1 | -1): number;
    /** Forgets what was learned (ceiling, floor, drops being judged); keeps the tier. */
    reset(): void;
  }

  export interface RatioTiers {
    /** Number of tiers (ratios.length). */
    count: number;
    /** Pixel ratio of a tier: min(ratios[tier], dpr). */
    ratio(tier: number): number;
    /** Same pixel ratio after the DPR cap (within 0.01) and the same extra(tier). */
    same(a: number, b: number): boolean;
  }

  /**
   * Pixel-ratio tiers for three.js games, capped by the display's DPR. `extra(tier)` is a key of
   * whatever else a tier changes (lights, effects); tiers with equal ratios and keys are the same.
   */
  export function ratioTiers(ratios: readonly number[], dpr: number, extra?: (tier: number) => string | number): RatioTiers;


  /** On 90/120/144 Hz screens, draw at most about `fps` frames a second (60). */
  export class FramePacer {
    constructor(fps?: number);
    readonly fps: number;
    /** ms between drawn frames (0: no cap). */
    readonly period: number;
    /** A new cap; 0 or Infinity: no cap. */
    set(fps: number): void;
    /** Call on every requestAnimationFrame with ms since the previous one; draw when true. */
    shouldDraw(dtMs: number): boolean;
  }


  export interface FrameSummary {
    /** Mean over the kept frames. */
    fps: number;
    /** Percentiles of the kept frame times, ms. */
    p50: number;
    p95: number;
    p99: number;
    max: number;
    /** Frames over 50 ms since the start or reset(). */
    long: number;
    /** Frames added since the start or reset(). */
    frames: number;
  }

  /** A ring of the last `n` frame times (600). */
  export class FrameStats {
    constructor(n?: number);
    /** Frame times kept now (at most the ring size). */
    readonly n: number;
    /** Frames over 50 ms since the start or reset(). */
    readonly long: number;
    /** Frames added since the start or reset(). */
    readonly total: number;
    /** One frame took `ms` (time between two drawn frames). */
    add(ms: number): void;
    /** Percentile `p` (0..1) of the kept frame times, ms (0 when empty). */
    pct(p: number): number;
    /** Mean frames per second over the kept frame times (0 when empty). */
    readonly fps: number;
    summary(): FrameSummary;
    reset(): void;
  }

  /** Time spent in named sections of a frame (net, sim, render...), averaged per frame. */
  export class SectionTimer {
    constructor();
    /** Frames begun since the last take(). */
    readonly frames: number;
    /** Starts a frame (now: performance.now()). */
    begin(now?: number): void;
    /** The time since the previous mark (or begin) belongs to `name`. */
    mark(name: string, now?: number): void;
    /** ms per frame of each section, then starts over. */
    take(): Record<string, number>;
  }


  export interface DeviceInfo {
    /** A phone or tablet: a coarse (finger) main pointer, iOS / iPadOS, or a mobile UA (Android, UA client hints). The screen size does not count. */
    mobile: boolean;
    /** iPhone, iPad, iPod, or a Macintosh with touch (iPadOS). */
    ios: boolean;
    android: boolean;
    /** devicePixelRatio, at most 3 (1 outside a browser). */
    dpr: number;
    /** navigator.hardwareConcurrency (0: unknown). */
    cores: number;
    /** navigator.deviceMemory in GB (0: unknown). */
    memory: number;
    /** The GPU name when a WebGL context is given and the browser tells it, else 'unknown'. */
    gpu: string;
    ua: string;
  }

  /** What kind of device this is, for defaults (starting tier, controls) and benchmark reports. */
  export function deviceInfo(gl?: WebGLRenderingContext | WebGL2RenderingContext | null): DeviceInfo;

  /** True when the page runs in a frame of another site (a claude.ai artifact, an ad); false at the top or outside a browser. */
  export function embedded(): boolean;

  /**
   * Why the browser caps the frame rate (QualityGovernor.cap), best guess, for the player's message:
   * 'tap' on WebKit (iOS, iPadOS, Safari on a Mac) when the page is embedded from another site and
   * nothing was tapped, clicked or typed yet (WebKit runs such a frame at 30 fps until then; a drag
   * does not count); otherwise 'low-power' on iOS / iPadOS (Low Power Mode) and 'saver' elsewhere
   * (a browser or system energy saver).
   */
  export function capCause(tapped: boolean, dev?: { ios: boolean; ua?: string }, framed?: boolean): 'tap' | 'low-power' | 'saver';

  export interface TapWatch {
    /** A click or tap reached the page. */
    readonly tapped: boolean;
    /** Stops listening. */
    stop(): void;
  }

  /**
   * Watches for the first click, mouse press or key press on the page (capture phase): what WebKit
   * counts as touching a frame; a drag makes none of them. `onTap` runs once, at that moment (call
   * the governor's recheck() there). Outside a browser `tapped` stays false.
   */
  export function tapWatch(onTap?: (() => void) | null, target?: EventTarget | null): TapWatch;
}

/** The three.js shell: phone-tuned renderer, viewport, fixed-tick loop, lost context, prompt queue, render and mesh helpers (pass THREE in). */
export namespace app {
  type DeviceInfo = perf.DeviceInfo;
  type FramePacer = perf.FramePacer;
  type FrameStats = perf.FrameStats;
  type QualityGovernor = perf.QualityGovernor;
  export const VERSION: string;

  /** Render scales per quality tier, best first (phones start at tier 1; desktops +0.25, max 2). */
  export const DEFAULT_RATIOS: readonly number[];


  /** The part of the three.js namespace the shell uses (pass the real `THREE`). */
  export interface ThreeLike {
    WebGLRenderer: new (parameters?: any) => any;
  }

  export interface AppOptions<T extends ThreeLike = any> {
    /** The three.js namespace (import * as THREE from 'three'); never imported by this module. */
    THREE: T;
    canvas: HTMLCanvasElement;
    /** Game ticks per second (0: none). */
    tickHz?: number;
    /** One game tick: read controls, send inputs, step prediction. */
    onTick?: () => void;
    /** Draw here (call app.render). dt: seconds, at most 0.1; alpha: fraction of the current tick, 0..1. */
    onFrame: (now: number, dt: number, alpha: number) => void;
    /** The canvas size (CSS px): first at app.start(), then on every change. */
    onResize?: (w: number, h: number) => void;
    /** The quality tier (scale effects with it): first at app.start(), then on every change. */
    onTier?: (tier: number) => void;
    /**
     * What your tiers change besides the render scale, as a key (e.g. `t => t >= 5 ? 'few-particles' : ''`).
     * The governor skips tiers that look the same: same render scale on this screen and same key.
     * Without it only the render scale counts.
     */
    tierKey?: (tier: number) => string | number;
    /**
     * The browser caps the frame rate whatever the game draws (fps: 30, sometimes 20), or no longer
     * does (fps 0); called again after the first tap if the cap is still there (the cause may have
     * changed). The governor finds it with 4 blank frames and keeps the quality; tell the player why
     * the game runs at 30: 'tap' (WebKit, a page embedded from another site: a tap lifts it),
     * 'low-power' (iOS Low Power Mode), 'saver' (an energy saver). See capCause in @horus/perf.
     */
    onCap?: (fps: number, cause: 'tap' | 'low-power' | 'saver') => void;
    /** Blank frames to find a browser frame-rate cap (true). */
    capProbe?: boolean;
    /** Render scale per tier, best first (DEFAULT_RATIOS); desktops add 0.25 (max 2) to the tiers at or above 1. */
    ratios?: readonly number[];
    /** 'auto' (default) or a fixed tier. */
    quality?: 'auto' | number;
    /** Extra WebGLRenderer parameters, over the shell's (antialias false, high-performance...). */
    renderer?: Record<string, unknown>;
    /** The context-lost message: [title, detail] (English by default). */
    texts?: { lost?: [string, string] };
  }

  export interface App<T extends ThreeLike = any> {
    THREE: T;
    /** The THREE.WebGLRenderer on `canvas`. */
    renderer: InstanceType<T['WebGLRenderer']>;
    gl: WebGLRenderingContext | WebGL2RenderingContext;
    /** deviceInfo(gl) of @horus/perf. */
    device: DeviceInfo;
    /** Full-screen text messages (loading, reconnecting, errors). */
    overlay: Overlay;
    /** Times between drawn frames. */
    stats: FrameStats;
    /** Set false while loading or paused: the governor does not count those frames. */
    live: boolean;
    /** True while the WebGL context is lost: onFrame still runs, app.render draws nothing, the governor does not count. */
    lost: boolean;
    /** renderer.info.reset(), then renderer.render(scene, camera); nothing while the context is lost. */
    render(scene: object, camera: object): void;
    viewport: Viewport;
    /** Drives viewport.setRatio (and onTier) from the frame rate; governor.cap is the browser's frame-rate cap (0: none). */
    governor: QualityGovernor;
    /** Why the browser caps the frame rate now (capCause of @horus/perf with the page's taps so far). */
    capCause(): 'tap' | 'low-power' | 'saver';
    loop: GameLoop;
    /** Starts the frame loop; the first call runs onResize and onTier once. */
    start(): void;
    stop(): void;
  }

  /**
   * The shell every three.js game needs, wired once: a renderer tuned for phones, a viewport that
   * follows the window, the quality governor driving the render scale, a frame loop with fixed game
   * ticks, context-loss handling and a message overlay.
   */
  export function createApp<T extends ThreeLike = any>(o: AppOptions<T>): App<T>;


  export interface GameLoopOptions {
    /** Game ticks per second (0: no ticks). */
    tickHz?: number;
    onTick?: () => void;
    /** dt: seconds since the last drawn frame, at most maxDt; alpha: fraction of the current tick. */
    onFrame: (now: number, dt: number, alpha: number) => void;
    /** Frame cap (60; 0: none). */
    fps?: number;
    /** Ticks per frame at most (5); a longer backlog is dropped. */
    maxTicks?: number;
    /** Seconds (0.1). */
    maxDt?: number;
    /**
     * First on every requestAnimationFrame (after the ticks, before the frame cap): true draws
     * nothing this frame and skips onFrame. createApp passes the governor's cap probe here.
     */
    blank?: (now: number) => boolean;
    /** For tests: requestAnimationFrame. */
    raf?: (f: FrameRequestCallback) => number;
    /** For tests: performance.now. */
    now?: () => number;
  }

  /** Drawn frames (requestAnimationFrame, capped at 60) and fixed-rate game ticks. */
  export class GameLoop {
    constructor(o: GameLoopOptions);
    /** ms per tick (0: no ticks). */
    readonly tickMs: number;
    maxTicks: number;
    maxDt: number;
    /** Change the frame cap with pacer.set(fps) (0: none). */
    readonly pacer: FramePacer;
    readonly running: boolean;
    /** Ticks run so far. */
    readonly ticks: number;
    /** Ticks dropped after stalls (hidden tab, debugger). */
    readonly dropped: number;
    /** Frames drawn so far. */
    readonly frames: number;
    /** Blank frames so far (blank() returned true). */
    readonly blanks: number;
    start(): void;
    stop(): void;
    /** One requestAnimationFrame step (start() schedules it). */
    frame(): void;
  }

  /** The part of a THREE.WebGLRenderer the viewport uses. */
  export interface ViewportRenderer {
    setPixelRatio(ratio: number): void;
    setSize(width: number, height: number, updateStyle?: boolean): void;
    domElement?: { style?: { width: string; height: string } } | null;
  }

  export interface ViewportOptions {
    /** Element whose size the canvas takes (default: the window). */
    fit?: HTMLElement | null;
    /** Update cameras here (CSS px). */
    onResize?: (w: number, h: number) => void;
    /** Initial pixel ratio (1). */
    ratio?: number;
  }

  /** Canvas size and render scale: follows the window (or `fit`) and the quality tier's pixel ratio. */
  export class Viewport {
    constructor(renderer: ViewportRenderer, o?: ViewportOptions);
    /** Size in CSS px (at least 1). */
    readonly w: number;
    readonly h: number;
    /** The pixel ratio rendered at. */
    readonly ratio: number;
    /** w / h. */
    readonly aspect: number;
    fit: HTMLElement | null;
    onResize: ((w: number, h: number) => void) | null;
    /** [w, h] it would take now. */
    size(): [number, number];
    /** Reads the size again, resizes the renderer and calls onResize (done on window resize). */
    resize(): void;
    /** Renders at this pixel ratio (a governor tier changed); nothing happens if it is the same. */
    setRatio(ratio: number): void;
    /** Removes the window listeners. */
    dispose(): void;
  }

  /** A full-screen message layer; text only (textContent), never HTML. */
  export class Overlay {
    /** parent: document.body by default; without a document the overlay does nothing. */
    constructor(parent?: HTMLElement | null);
    /** The layer (it carries data-ui); null outside a browser. */
    readonly el: HTMLDivElement | null;
    /** Shows `text` and a smaller `detail`; with `button`, a button that runs `action`. Returns an id for hide(id). */
    show(text: string, detail?: string, button?: string | null, action?: (() => void) | null): number;
    /** Hides the overlay; with an id from show, only if that message is still the one shown. */
    hide(id?: number): void;
    readonly shown: boolean;
  }

  /** Base64 (a WASM inlined by @horus/build with inline:base64:) to bytes. */
  export function base64ToBytes(b64: string): Uint8Array;


  /** A tip as the queue keeps it. */
  export interface Tip {
    text: string;
    /** When it is dropped if still waiting (the queue's clock, ms). */
    until: number;
    /** ms on screen. */
    duration: number;
    /** What tip() was given as data (for a renderer). */
    data?: unknown;
  }

  export interface PromptHooks {
    /** Put the tip on screen. */
    show?: (tip: Tip) => void;
    /** Take it off. */
    hide?: (tip: Tip) => void;
    /** Show a toast (it does not wait). */
    toast?: (text: string, o: ToastOptions) => void;
    /** Clear the toasts on screen (a quiet title came up). */
    clearToasts?: () => void;
    /** A big title came up (true) or went (false): step the HUD back. */
    title?: (on: boolean) => void;
  }

  export interface PromptQueueOptions extends PromptHooks {
    /** Something else is on screen (a modal, an ad, a tutorial pointer): tips wait. */
    busy?: () => boolean;
    /** ms a tip stays (3400). */
    duration?: number;
    /** ms a tip may wait before it is dropped (8000). */
    ttl?: number;
    /** ms between checks while tips wait (500). */
    poll?: number;
    /** For tests: the clock and timers. */
    now?: () => number;
    setTimeout?: (f: () => void, ms: number) => any;
    clearTimeout?: (id: any) => void;
  }

  export interface ToastOptions {
    /** A class for PromptView's toast element. */
    kind?: string;
    /** ms on screen (PromptView: 1550, 2650 past 20 characters). */
    ms?: number;
  }

  /**
   * One tip at a time, shown only when the screen is free, dropped after waiting too long; toasts
   * held back while a quiet big title is up. Knows no DOM: hooks draw (or use createPrompts).
   */
  export class PromptQueue {
    constructor(o?: PromptQueueOptions);
    duration: number;
    ttl: number;
    poll: number;
    /** Tips not shown yet, in order. */
    readonly waiting: Tip[];
    /** The tip on screen, or null. */
    readonly current: Tip | null;
    /** A big title is up. */
    readonly titleUp: boolean;
    /** A tip could go on screen now. */
    readonly free: boolean;
    readonly stats: { shown: number; dropped: number; toasts: number; blocked: number };
    /** Queues a tip; false when the same text is already waiting or on screen. first: before the others. */
    tip(text: string, o?: { ttl?: number; duration?: number; first?: boolean; data?: unknown }): boolean;
    /** A toast now; false (dropped) while a quiet title is up. */
    toast(text: string, o?: ToastOptions): boolean;
    /** A big title for `ms` (2600): tips wait; quiet (default true) also drops toasts and clears them. Extends one already up. */
    title(ms?: number, o?: { quiet?: boolean }): void;
    /** Ends the title now. */
    endTitle(): void;
    /** Something the queue cannot see is on screen until the returned release() (holds of one key count). */
    hold(key?: string): () => void;
    /** Releases one hold of `key` (every one with all). */
    release(key?: string, all?: boolean): void;
    /** Takes the tip on screen down now. */
    dismiss(): void;
    /** Drops the waiting tips. */
    clear(): void;
    /** Shows the next tip if it can (call after busy() turns false to skip the poll delay). */
    pump(): void;
    dispose(): void;
  }

  export interface PromptViewOptions {
    /** Toasts on screen at most (4). */
    maxToasts?: number;
    /** ms a toast stays. */
    toastMs?: (text: string) => number;
    /** Class on the parent while a title is up ('hk-title'). */
    titleClass?: string;
    /** false: no inline look; style .hk-tip, .hk-tip.on, .hk-toasts, .hk-toast in the game's CSS. */
    style?: boolean;
    setTimeout?: (f: () => void, ms: number) => any;
  }

  /** The DOM renderer: a tip line and a toast stack in `parent`, text only (textContent), data-ui. */
  export class PromptView {
    constructor(parent?: HTMLElement | null, o?: PromptViewOptions);
    readonly tipEl: HTMLDivElement | null;
    readonly toastsEl: HTMLDivElement | null;
    show(tip: Tip): void;
    hide(tip?: Tip): void;
    toast(text: string, o?: ToastOptions): void;
    clearToasts(): void;
    title(on: boolean): void;
    /** The hooks for PromptQueue. */
    hooks(): Required<PromptHooks>;
    dispose(): void;
  }

  /** A PromptQueue drawn by a PromptView in `parent` (queue.view); dispose() removes both. */
  export function createPrompts(parent: HTMLElement | null, o?: PromptQueueOptions & PromptViewOptions): PromptQueue & { view: PromptView };


  /**
   * updateWorld(root, force?): the world matrices scene.updateMatrixWorld() computes, to the bit,
   * composing only what moved. Set scene.matrixWorldAutoUpdate = false and call it once per frame.
   */
  export function createWorldUpdater(THREE: any): (root: any, force?: boolean) => void;

  /** Draws the shadow map again only when a visible caster or a shadow-casting light moved. */
  export class ShadowGate {
    /** Turns renderer.shadowMap.autoUpdate off. epsilon: movements below it are ignored (1e-5). */
    constructor(renderer: { shadowMap: { autoUpdate: boolean; needsUpdate: boolean } }, scene: any, o?: { epsilon?: number });
    epsilon: number;
    readonly frames: number;
    readonly redraws: number;
    /** After the matrices are up to date, before rendering; true when the map will be drawn this frame. */
    update(): boolean;
    /** The next update() draws the map. */
    invalidate(): void;
    /** autoUpdate back on. */
    dispose(): void;
  }

  export interface PrecompileOptions {
    /** The render target the scene draws into (default: the renderer's current one). */
    target?: any;
    /** true: leave this hidden object hidden. */
    skip?: (object: any) => boolean;
    /** false: compile only, no frame. */
    frame?: boolean;
  }

  /** Shaders compiled (compileAsync where it can) and first used now, in one frame with every hidden object shown and nothing culled. */
  export function precompile(renderer: any, scene: any, camera: any, o?: PrecompileOptions): Promise<{ shown: number; culled: number; async: boolean }>;

  export interface IdleSchedulerOptions {
    /** The player is playing: no background work at all. */
    playing?: () => boolean;
    /** Nothing is going on: work done ahead of time may run. */
    idle?: () => boolean;
    /** ms between checks while waiting (400). */
    poll?: number;
    setTimeout?: (f: () => void, ms: number) => any;
    clearTimeout?: (id: any) => void;
  }

  /** Background jobs one at a time: wanted ones unless playing, ahead-of-time ones only while idle. */
  export class IdleScheduler {
    constructor(o?: IdleSchedulerOptions);
    playing: () => boolean;
    idle: () => boolean;
    poll: number;
    readonly size: number;
    readonly busy: boolean;
    readonly stats: { done: number; failed: number };
    /** fn(calm): await calm() between steps. ahead: only while idle; first: before the others; key: one job per key (promoted when wanted). */
    add<T>(fn: (calm: () => Promise<void>) => T | Promise<T>, o?: { ahead?: boolean; first?: boolean; key?: unknown }): Promise<T>;
    /** Resolves when the running job may go on. */
    calm(): Promise<void>;
    pump(): void;
    /** Drops the waiting jobs (their promises resolve to undefined). */
    clear(): void;
    dispose(): void;
  }

  /** Pointers on the screen: idle() is false while one is down (up to `stuck` ms, 5000) and for `quiet` ms (1000) after the last event. */
  export function pointerIdle(target?: { addEventListener: Function; removeEventListener: Function } | null, o?: { quiet?: number; stuck?: number; now?: () => number }): { readonly down: number; idle(): boolean; dispose(): void };

  export interface PostOptions {
    /** MSAA samples of the scene target (0). */
    msaa?: number;
    toneMapping?: 'neutral' | 'aces' | 'agx' | 'reinhard' | 'cineon' | 'linear' | 'none';
    bloom?: { strength?: number; radius?: number; threshold?: number; enabled?: boolean };
    vignette?: number;
    saturation?: number;
    contrast?: number;
  }

  export interface PostComposer {
    /** Instead of renderer.render(scene, camera). */
    render(): void;
    /** CSS px, with the viewport. */
    setSize(w: number, h: number): void;
    setPixelRatio(ratio: number): void;
    setSamples(n: number): void;
    readonly samples: number;
    /** What the scene draws into (pass it to precompile). */
    readonly target: any;
    readonly width: number;
    readonly height: number;
    dispose(): void;
  }

  /** HDR scene target, a quarter / eighth resolution bloom and one final pass (grade, vignette, flash, tone mapping, sRGB). */
  export function createPost(THREE: any, renderer: any, scene: any, camera: any, o?: PostOptions): {
    composer: PostComposer;
    /** Live settings: strength, radius (0..1: quarter vs eighth res halo), threshold, enabled. */
    bloom: { strength: number; radius: number; threshold: number; enabled: boolean };
    /** The final pass's uniforms: uFlash (0..1), uFlashCol, uTint, uDim, uAb (chromatic aberration), uVig, uSat, uCon. */
    uniforms: Record<string, { value: any }>;
  };

  /** A render target's pixels read back behind a fence (rows bottom-up); null where it cannot (WebGL 1, lost context, timeout). */
  export function readPixelsAsync(renderer: any, target: any, o?: { x?: number; y?: number; width?: number; height?: number; calm?: () => Promise<void>; timeout?: number; wait?: (ms: number) => Promise<void> }): Promise<Uint8Array | null>;

  /** Pixels cropped to what is drawn, rows top-down, coverage taken out: ImageData-shaped. */
  export function trimAlpha(px: ArrayLike<number>, width: number, height: number, o?: { threshold?: number; pad?: number; flipY?: boolean; premultiplied?: boolean }): { width: number; height: number; data: Uint8ClampedArray; x: number; y: number };

  /** A PNG of an ImageData-shaped picture, encoded on a worker where it can; null where nothing can encode. */
  export function encodePng(img: { width: number; height: number; data: ArrayLike<number> }, o?: { worker?: boolean; timeout?: number }): Promise<Blob | null>;

  /** One attribute of a part: a geometry's array as it is (quantized, interleaved with stride/offset). */
  export interface MeshPartAttribute { array: ArrayLike<number> & { constructor: any; buffer?: ArrayBufferLike; length: number }; itemSize: number; normalized: boolean; stride?: number; offset?: number }
  /** A geometry as plain arrays and the matrix it is drawn with (16 elements, column-major as Matrix4.elements). */
  export interface MeshPart { attrs: Record<string, MeshPartAttribute>; index: ArrayLike<number> | null; matrix: ArrayLike<number> }
  /** Merged arrays: position, normal, uv, color as Float32 (itemSize 3, 3, 2, 3); index Uint16 or Uint32; sphere = [cx, cy, cz, r]. */
  export interface MergedMesh { attrs: Record<'position' | 'normal' | 'uv' | 'color', { array: Float32Array; itemSize: number; normalized: false }>; index: Uint16Array | Uint32Array | null; sphere: [number, number, number, number] }

  /** Parts -> one mesh's arrays, the floats three 0.186 gives (Hill Sling's floatGeo + mergeGeometries); null when they cannot be merged. No three. */
  export function mergeMeshData(parts: MeshPart[]): MergedMesh | null;
  /** A three geometry and its matrix (a Matrix4 or 16 numbers) -> a part; copy (default true) copies the arrays, once per interleaved buffer. */
  export function geometryPart(geometry: any, matrix: { elements: ArrayLike<number> } | ArrayLike<number>, o?: { copy?: boolean }): MeshPart;
  /** Merged arrays -> a THREE.BufferGeometry with its bounding sphere set. */
  export function toGeometry(THREE: any, merged: MergedMesh): any;
  /** [{ geometry, matrix }] -> one THREE.BufferGeometry on the main thread; null when they cannot be merged. */
  export function mergeParts(THREE: any, parts: Array<{ geometry: any; matrix: any }>): any | null;
  /** Groups of [{ geometry, matrix }] -> one merged result per group, on a worker (inline source, no three); on the main thread where there is none, or when it fails or passes `timeout` (10000 ms). */
  export function mergePartsAsync(groups: Array<Array<{ geometry: any; matrix: any }>>, o?: { worker?: boolean; timeout?: number }): Promise<Array<MergedMesh | null>>;
}

/** GPU effects for three.js: sparks, glows, smoke, rings, decals, damage numbers, coin fly (pass THREE in). */
export namespace fx {
  export const VERSION: string;

  /** A point or a direction: `[x, y, z]` (any array-like) or an object with x, y, z (a THREE.Vector3). */
  export type Vec3Like = ArrayLike<number> | { x: number; y?: number; z?: number };

  /** A fixed value, or `[min, max]`: each particle draws uniformly between them. */
  export type Range = number | readonly [number, number] | readonly [number];

  /** 0xRRGGBB, or a CSS hex string '#rgb' / '#rrggbb'. Display (sRGB) colours, written as is. */
  export type Color = number | string;

  /** Particle shapes. spark: a streak along its velocity on screen that shrinks; glow: a soft round dot; smoke: a soft puff that grows and turns. */
  export type Kind = 'spark' | 'glow' | 'smoke';

  /** 'add': light adds up (sparks, glows, fire); 'alpha': covers what is behind (smoke, dust, blood). */
  export type Blend = 'add' | 'alpha';

  export interface KindDefaults {
    readonly speed: readonly [number, number];
    readonly life: readonly [number, number];
    readonly size: readonly [number, number];
    readonly size2: number;
    readonly gravity: number;
    readonly drag: number;
    readonly blend: Blend;
  }

  /** Defaults of burst() and emit() for each kind (the README has the table). */
  export const KIND_DEFAULTS: Readonly<Record<Kind, KindDefaults>>;

  /** Effect time (seconds since the epoch) past which update() rebases every time (1024). */
  export const REBASE: number;

  /** The 43 characters numbers can show: digits, + - . ! % x / and A-Z. */
  export const GLYPHS: string;

  /** 0xRRGGBB from a number or '#rgb' / '#rrggbb'; throws on anything else. */
  export function toHex(c: Color): number;

  /** How a number is shown: integers up to 99999, then thousands with K (123K), then millions with M. */
  export function formatNumber(v: number): string;

  export interface FxOptions {
    /** Additive billboards (sparks, glows): 4096. 0: none. */
    sparks?: number;
    /** Alpha-blended billboards (smoke): 1024. */
    smoke?: number;
    /** Rings and decals on the ground: 512. */
    ground?: number;
    /** Glyphs of floating numbers (one per character): 1024. */
    glyphs?: number;
    /** renderOrder of the ground mesh; smoke, sparks and numbers take the next three (10). */
    renderOrder?: number;
    /** true when rendering into a linear render target (post-processing): colours are converted from sRGB in the shader (false). */
    linear?: boolean;
    /** CSS font family of the numbers ('system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif'). */
    font?: string;
    /** Font weight of the numbers (900). */
    weight?: string | number;
    /** Makes the canvas of the glyph atlas (default: document.createElement, else OffscreenCanvas; null: never draw). */
    canvas?: ((width: number, height: number) => any) | null;
  }

  export interface BurstOptions {
    /** Where the particles start. */
    at: Vec3Like;
    /** How many (8), times fx.scale; a burst of 1 or more keeps at least 1 while scale > 0. */
    n?: number;
    kind?: Kind;
    /** Which ring (default by kind: spark and glow 'add', smoke 'alpha'). */
    blend?: Blend;
    /** Launch speed, m/s (by kind; spark [2, 6]). */
    speed?: Range;
    /** Centre of the cone of directions ([0, 1, 0]). */
    dir?: Vec3Like;
    /** Half-angle of the cone as a fraction of 180 degrees: 0 along dir, 0.5 a hemisphere, 1 every direction (1). */
    spread?: number;
    /** Particles start anywhere within this distance of `at` (0). */
    radius?: number;
    /** Seconds (by kind; spark [0.3, 0.7]). */
    life?: Range;
    /** World units at birth (by kind; spark [0.06, 0.14]). */
    size?: Range;
    /** Size at the end of life, as a multiple of the birth size (by kind: spark 0.3, glow 0.6, smoke 2.5). */
    size2?: number;
    /** One colour, or a list to pick from per particle (white). */
    color?: Color | readonly Color[];
    /** Colour at the end of life (the birth colour). */
    color2?: Color;
    /** Opacity (1); above 1 brightens additive particles. */
    alpha?: number;
    /** m/s² on y (by kind: spark -9.8, glow -1, smoke 0.6 rises). */
    gravity?: number;
    /** Exponential slow-down of the launch velocity, 1/s (by kind: spark 0, glow 2, smoke 2.5). */
    drag?: number;
    /** Seconds before each particle appears (0). */
    delay?: Range;
    /** Same seed, same burst. */
    seed?: number;
  }

  export interface EmitOptions {
    at: Vec3Like;
    /** Velocity, m/s ([0, 0, 0]). */
    vel?: Vec3Like;
    kind?: Kind;
    blend?: Blend;
    /** Seconds (the middle of the kind's range). */
    life?: number;
    /** World units (the middle of the kind's range). */
    size?: number;
    size2?: number;
    color?: Color;
    color2?: Color;
    alpha?: number;
    gravity?: number;
    drag?: number;
    delay?: number;
    seed?: number;
  }

  export interface RingOptions {
    /** Centre; the ring lies on the plane y = at[1] (a little above it). */
    at: Vec3Like;
    /** Radius it opens to, world units (1). */
    radius?: number;
    /** Width of the band, world units (0.15). */
    width?: number;
    /** Seconds (0.4). */
    life?: number;
    /** White. */
    color?: Color;
    alpha?: number;
    /** 'add' (default) or 'alpha'. */
    blend?: Blend;
    delay?: number;
    seed?: number;
  }

  export interface DecalOptions {
    /** Centre; the decal lies on the plane y = at[1] (a little above it). */
    at: Vec3Like;
    /** World units (0.6). */
    radius?: number;
    /** Seconds (3); it fades out over the last 30 %. */
    life?: number;
    /** Black. */
    color?: Color;
    /** 0.6. */
    alpha?: number;
    /** 'alpha' (default) or 'add'. */
    blend?: Blend;
    delay?: number;
    seed?: number;
  }

  export interface NumberOptions {
    /** White. */
    color?: Color;
    /** Height of the digits, world units (0.5). */
    size?: number;
    /** Seconds (0.9); fades over the last 30 %. */
    life?: number;
    /** How far it rises on screen over its life, world units (1.2). */
    rise?: number;
    /** Sideways drift on screen, world units: a random amount in [-drift, drift] per number (0.3). */
    drift?: number;
    /** Starts 1.8 times bigger and settles in about 0.15 s (true). */
    pop?: boolean;
    delay?: number;
    seed?: number;
  }

  export interface HitOptions {
    /** Spray the sparks towards this direction (a 54 degree cone) instead of every way. */
    dir?: Vec3Like;
    /** Sparks (10). */
    n?: number;
    color?: Color;
    color2?: Color;
    /** Size of the flash (0.5). */
    size?: number;
    seed?: number;
  }

  export interface ExplosionOptions {
    /** World units (2): sets the counts, speeds and sizes. */
    radius?: number;
    color?: Color;
    /** y of the ground for the ring and the scorch mark (0). */
    ground?: number;
    seed?: number;
  }

  export interface FxStats {
    /** Particles, rings, decals and glyphs written so far. */
    written: number;
    /** Writes that replaced an effect still alive (a ring was full). */
    overwritten: number;
    /** Floats queued for upload by the last update(). */
    uploadedFloats: number;
    /** Meshes visible after the last update() (0 to 4). */
    drawCalls: number;
  }

  /**
   * Stateless GPU effects: each effect is written once into a ring of instanced attributes and
   * the vertex shader moves it; at most 4 draw calls, none when idle; only written slots are
   * uploaded. Call update(time) once per frame before rendering.
   */
  export class Fx {
    /**
     * @param THREE the three.js namespace (`import * as THREE from 'three'`)
     * @param parent the scene, or any Object3D the effects should go into (its transform applies)
     */
    constructor(THREE: any, parent: { add(...objects: any[]): any }, options?: FxOptions);

    /** Multiplies every burst's count (quality): 1. */
    scale: number;
    /** Particles burst() may write between two updates (Infinity); the rest are dropped. */
    budget: number;
    /** Effect time of the last update(): seconds since the epoch (the first update), rebased past REBASE. */
    readonly time: number;
    readonly stats: FxStats;
    /** The Group holding the meshes (added to the parent). */
    readonly group: any;
    /** The meshes in draw order: fx.ground, fx.smoke, fx.sparks, fx.numbers (a ring of capacity 0 has none). */
    readonly meshes: readonly any[];

    /** A spray of particles. Returns how many were written (after scale and budget). */
    burst(o: BurstOptions): number;
    /** One particle with an exact velocity. Returns 1 (0 without that ring). */
    emit(o: EmitOptions): number;
    /** A ring on the ground opening to `radius`. Returns 1 (0 without a ground ring). */
    ring(o: RingOptions): number;
    /** A soft irregular disc on the ground that fades out. Returns 1 (0 without a ground ring). */
    decal(o: DecalOptions): number;
    /**
     * A floating number or short text, facing the camera, always on top. Numbers are rounded and
     * shortened (formatNumber); characters outside GLYPHS are skipped. Returns the glyphs written (at most 64).
     */
    number(at: Vec3Like, value: number | string, o?: NumberOptions): number;
    /** Sparks and a flash. Returns the particles written. */
    hit(at: Vec3Like, o?: HitOptions): number;
    /** Sparks, a flash, smoke, a ground ring and a scorch mark. Returns the effects written. */
    explosion(at: Vec3Like, o?: ExplosionOptions): number;

    /**
     * Once per frame before rendering. `time`: the frame's time in seconds on any clock that moves
     * forward (performance.now() / 1000, or the game clock). Effects written since the last update
     * are born at this time; their slots are queued for upload; meshes with nothing alive hide.
     */
    update(time: number): void;
    /** Ends every effect now. */
    clear(): void;
    /** Removes the group from its parent and frees geometries, materials and the glyph atlas. */
    dispose(): void;
  }


  /** Something drawImage takes: a canvas, an image, an ImageBitmap. */
  export type SpriteImage = CanvasImageSource & { width: number; height: number };
  /** A sprite, or a maker drawing one at `px` device pixels wide (called once per pixel ratio). */
  export type SpriteSource = SpriteImage | ((px: number, makeCanvas: (w: number, h: number) => HTMLCanvasElement) => SpriteImage);

  export interface CoinKind {
    /** The piece; its width is shown as the burst's `size` (CSS px), aspect kept. */
    face: SpriteSource;
    /** The coin's edge, drawn behind the face as it flips (spin 'flip'). */
    edge?: SpriteSource | null;
    /** Colour of the glow, flashes and twinkles: 0xRRGGBB, '#rgb', '#rrggbb' or 'r,g,b'; default white. */
    glow?: number | string;
    /** 'flip' (a coin turning: default with an edge), 'wobble' (a gem), 'none' (default without an edge). */
    spin?: 'flip' | 'wobble' | 'none';
  }

  export type Point = { x: number; y: number };
  /** A point in the parent's box (CSS px), an element (its centre), or a function giving either (read every frame). */
  export type PointLike = Point | Element | (() => Point | Element);

  export interface CoinFlyOptions {
    /** The kinds burst() can draw; default { coin, gem } drawn with coinSprites() and gemSprite(). */
    kinds?: Record<string, CoinKind>;
    /** Default piece size in CSS px (34). */
    size?: number;
    /** Device pixel ratio cap (2). */
    maxDpr?: number;
    /** z-index of the canvas. */
    zIndex?: number | string;
    /** Class of the canvas. */
    className?: string;
    /** For tests: the pixel ratio (default window.devicePixelRatio), canvases, clock, frames and random numbers. */
    dpr?: number | (() => number);
    canvas?: (w: number, h: number) => any;
    now?: () => number;
    raf?: (f: () => void) => number;
    caf?: (id: number) => void;
    random?: () => number;
  }

  export interface CoinBurstOptions {
    /** The source point (CSS px in the parent's box), or `from`. */
    x?: number;
    y?: number;
    /** An element (its centre) or a point instead of x, y. */
    from?: PointLike;
    /** Pieces (16). */
    n?: number;
    /** A kind of the CoinFly ('coin'). */
    kind?: string;
    /** Keeps the cloud on a moving point (a car while the camera orbits). */
    anchor?: (() => Point) | null;
    /** CSS px (the CoinFly's size). */
    size?: number;
    /** Cloud radius factor (1). */
    spread?: number;
    /** How far above the source the cloud hangs, as a factor (1). */
    up?: number;
    /** The tight, fast pop of a button reward (false). */
    quick?: boolean;
    /** A flash and stars at the source (true). */
    flash?: boolean;
  }

  export interface CoinCollectOptions {
    /** The counter: an element (its centre), a point, or a function giving one. */
    to?: PointLike;
    /** As each piece lands: i = 0..n-1. */
    onArrive?: (i: number, n: number) => void;
    /** After the last one (at once when nothing is left to collect). */
    onDone?: () => void;
    /** Seconds before the first leaves (0; shower: 0.38). */
    delay?: number;
    /** Seconds between departures (0.042), squeezed for groups over 18. */
    stagger?: number;
    /** Seconds of flight (0.56). */
    dur?: number;
  }

  /**
   * Coins and gems flying into a UI counter, on one 2D canvas over `parent` (DOM only, no three.js;
   * requestAnimationFrame only while something is on screen). Without a parent or a document
   * every method does nothing and collect() calls onDone at once.
   */
  export class CoinFly {
    constructor(parent: HTMLElement | null, o?: CoinFlyOptions);
    readonly canvas: HTMLCanvasElement | null;
    /** True while pieces are on screen. */
    readonly busy: boolean;
    readonly stats: { drawn: number; frames: number; landed: number };
    /** Pieces pop out of a point and hover there. Returns a group id for collect() (0: nothing drawn). */
    burst(o: CoinBurstOptions): number;
    /** Every piece of a group flies into the counter, nearest first, along one shared arc. */
    collect(gid: number, o?: CoinCollectOptions): void;
    /** burst() then collect() 0.38 s later. Returns the group id. */
    shower(o: CoinBurstOptions, collect?: CoinCollectOptions): number;
    /** Drops everything at once (no onArrive / onDone for them). */
    clear(): void;
    /** Removes the canvas and stops the frames. */
    dispose(): void;
  }

  /** new CoinFly(parent, o). */
  export function createCoinFly(parent: HTMLElement | null, o?: CoinFlyOptions): CoinFly;

  export interface CoinColors { light?: string; mid?: string; dark?: string; rim?: string; star?: string; edgeTop?: string; edgeBottom?: string }
  /** A gold coin (face with rim, ring, embossed star and glint; darker edge) as sprite makers; colours to change it. */
  export function coinSprites(o?: CoinColors): { face: SpriteSource; edge: SpriteSource };

  export interface GemColors { body?: string; table?: string; left?: string; right?: string; lowLeft?: string; low?: string; lowRight?: string; outline?: string }
  /** A cut gem (crown and pavilion facets) as a sprite maker; colours to change it. */
  export function gemSprite(o?: GemColors): SpriteSource;
}
