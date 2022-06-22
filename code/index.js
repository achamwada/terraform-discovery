exports.handler = async (event, context) => {
    let statusCode = 200
    let body = 'Hello from Lambda!'
    const { awsRequestId } = context
    const contentEntryKey = event.params.querystring.contentEntryKey
    if (contentEntryKey === 'test404') {
        statusCode = 404
        body = 'Content not found'
        context.fail(JSON.stringify({
            statusCode,
            body,
            contentEntryKey,
            awsRequestId
        }))
    }
    if (contentEntryKey === 'test500') {
        statusCode = 500
        body = 'Server Error'
        const response = {
            "statusCode": statusCode,
            "body": body,
            awsRequestId
        }
        return context.fail(JSON.stringify(response))
    }
    return {
        statusCode,
        body,
        awsRequestId
    };
};