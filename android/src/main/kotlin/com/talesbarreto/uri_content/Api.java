// Autogenerated from Pigeon (v10.1.6), do not edit directly.
// See also: https://pub.dev/packages/pigeon

package com.talesbarreto.uri_content;

import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.StandardMessageCodec;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Generated class from Pigeon. */
@SuppressWarnings({"unused", "unchecked", "CodeBlock2Expr", "RedundantSuppression", "serial"})
public class Api {

  /** Error class for passing custom error details to Flutter via a thrown PlatformException. */
  public static class FlutterError extends RuntimeException {

    /** The error code. */
    public final String code;

    /** The error details. Must be a datatype supported by the api codec. */
    public final Object details;

    public FlutterError(@NonNull String code, @Nullable String message, @Nullable Object details) 
    {
      super(message);
      this.code = code;
      this.details = details;
    }
  }

  @NonNull
  protected static ArrayList<Object> wrapError(@NonNull Throwable exception) {
    ArrayList<Object> errorList = new ArrayList<Object>(3);
    if (exception instanceof FlutterError) {
      FlutterError error = (FlutterError) exception;
      errorList.add(error.code);
      errorList.add(error.getMessage());
      errorList.add(error.details);
    } else {
      errorList.add(exception.toString());
      errorList.add(exception.getClass().getSimpleName());
      errorList.add(
        "Cause: " + exception.getCause() + ", Stacktrace: " + Log.getStackTraceString(exception));
    }
    return errorList;
  }

  public interface Result<T> {
    @SuppressWarnings("UnknownNullness")
    void success(T result);

    void error(@NonNull Throwable error);
  }
  /** Generated interface from Pigeon that represents a handler of messages from Flutter. */
  public interface UriContentNativeApi {

    void getContentFromUri(@NonNull String url, @NonNull Long requestId, @NonNull Long bufferSize);

    void cancelRequest(@NonNull Long requestId);

    void doesFileExist(@NonNull String url, @NonNull Result<Boolean> result);

    /** The codec used by UriContentNativeApi. */
    static @NonNull MessageCodec<Object> getCodec() {
      return new StandardMessageCodec();
    }
    /**Sets up an instance of `UriContentNativeApi` to handle messages through the `binaryMessenger`. */
    static void setup(@NonNull BinaryMessenger binaryMessenger, @Nullable UriContentNativeApi api) {
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(
                binaryMessenger, "dev.flutter.pigeon.uri_content.UriContentNativeApi.getContentFromUri", getCodec());
        if (api != null) {
          channel.setMessageHandler(
              (message, reply) -> {
                ArrayList<Object> wrapped = new ArrayList<Object>();
                ArrayList<Object> args = (ArrayList<Object>) message;
                String urlArg = (String) args.get(0);
                Number requestIdArg = (Number) args.get(1);
                Number bufferSizeArg = (Number) args.get(2);
                try {
                  api.getContentFromUri(urlArg, (requestIdArg == null) ? null : requestIdArg.longValue(), (bufferSizeArg == null) ? null : bufferSizeArg.longValue());
                  wrapped.add(0, null);
                }
 catch (Throwable exception) {
                  ArrayList<Object> wrappedError = wrapError(exception);
                  wrapped = wrappedError;
                }
                reply.reply(wrapped);
              });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(
                binaryMessenger, "dev.flutter.pigeon.uri_content.UriContentNativeApi.cancelRequest", getCodec());
        if (api != null) {
          channel.setMessageHandler(
              (message, reply) -> {
                ArrayList<Object> wrapped = new ArrayList<Object>();
                ArrayList<Object> args = (ArrayList<Object>) message;
                Number requestIdArg = (Number) args.get(0);
                try {
                  api.cancelRequest((requestIdArg == null) ? null : requestIdArg.longValue());
                  wrapped.add(0, null);
                }
 catch (Throwable exception) {
                  ArrayList<Object> wrappedError = wrapError(exception);
                  wrapped = wrappedError;
                }
                reply.reply(wrapped);
              });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(
                binaryMessenger, "dev.flutter.pigeon.uri_content.UriContentNativeApi.doesFileExist", getCodec());
        if (api != null) {
          channel.setMessageHandler(
              (message, reply) -> {
                ArrayList<Object> wrapped = new ArrayList<Object>();
                ArrayList<Object> args = (ArrayList<Object>) message;
                String urlArg = (String) args.get(0);
                Result<Boolean> resultCallback =
                    new Result<Boolean>() {
                      public void success(Boolean result) {
                        wrapped.add(0, result);
                        reply.reply(wrapped);
                      }

                      public void error(Throwable error) {
                        ArrayList<Object> wrappedError = wrapError(error);
                        reply.reply(wrappedError);
                      }
                    };

                api.doesFileExist(urlArg, resultCallback);
              });
        } else {
          channel.setMessageHandler(null);
        }
      }
    }
  }
  /** Generated class from Pigeon that represents Flutter messages that can be called from Java. */
  public static class UriContentFlutterApi {
    private final @NonNull BinaryMessenger binaryMessenger;

    public UriContentFlutterApi(@NonNull BinaryMessenger argBinaryMessenger) {
      this.binaryMessenger = argBinaryMessenger;
    }

    /** Public interface for sending reply. */ 
    @SuppressWarnings("UnknownNullness")
    public interface Reply<T> {
      void reply(T reply);
    }
    /** The codec used by UriContentFlutterApi. */
    static @NonNull MessageCodec<Object> getCodec() {
      return new StandardMessageCodec();
    }
    public void onDataReceived(@NonNull Long requestIdArg, @Nullable byte[] dataArg, @Nullable String errorArg, @NonNull Reply<Void> callback) {
      BasicMessageChannel<Object> channel =
          new BasicMessageChannel<>(
              binaryMessenger, "dev.flutter.pigeon.uri_content.UriContentFlutterApi.onDataReceived", getCodec());
      channel.send(
          new ArrayList<Object>(Arrays.asList(requestIdArg, dataArg, errorArg)),
          channelReply -> callback.reply(null));
    }
  }
}
